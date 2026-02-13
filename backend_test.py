#!/usr/bin/env python3
"""
Society Financial Management API Test Suite
Tests all backend APIs with demo user credentials
"""
import requests
import sys
import json
from datetime import datetime

class SocietyFinanceAPITester:
    def __init__(self, base_url="https://community-accounting.preview.emergentagent.com"):
        self.base_url = base_url.rstrip('/')
        self.token = None
        self.user_info = None
        self.society_id = None
        self.tests_run = 0
        self.tests_passed = 0
        self.failed_tests = []
        self.session = requests.Session()

    def log(self, message, status="INFO"):
        timestamp = datetime.now().strftime("%H:%M:%S")
        symbols = {"PASS": "✅", "FAIL": "❌", "INFO": "ℹ️ ", "WARN": "⚠️ "}
        print(f"{symbols.get(status, '•')} [{timestamp}] {message}")

    def run_test(self, name, method, endpoint, expected_status=200, data=None, description=""):
        """Run a single API test"""
        url = f"{self.base_url}{endpoint}"
        headers = {'Content-Type': 'application/json'}
        if self.token:
            headers['Authorization'] = f'Bearer {self.token}'

        self.tests_run += 1
        self.log(f"Testing: {name} - {description}")
        
        try:
            if method == 'GET':
                response = self.session.get(url, headers=headers, timeout=10)
            elif method == 'POST':
                response = self.session.post(url, json=data, headers=headers, timeout=10)
            elif method == 'PUT':
                response = self.session.put(url, json=data, headers=headers, timeout=10)
            else:
                raise ValueError(f"Unsupported method: {method}")

            success = response.status_code == expected_status
            
            if success:
                self.tests_passed += 1
                self.log(f"PASS - {name} (Status: {response.status_code})", "PASS")
                try:
                    return True, response.json()
                except:
                    return True, {}
            else:
                self.log(f"FAIL - {name} (Expected {expected_status}, got {response.status_code})", "FAIL")
                self.log(f"Response: {response.text[:200]}...", "WARN")
                self.failed_tests.append({
                    "name": name,
                    "endpoint": endpoint,
                    "expected_status": expected_status,
                    "actual_status": response.status_code,
                    "response": response.text[:300]
                })
                return False, {}

        except requests.exceptions.RequestException as e:
            self.log(f"FAIL - {name} - Network error: {str(e)}", "FAIL")
            self.failed_tests.append({
                "name": name,
                "endpoint": endpoint,
                "error": str(e)
            })
            return False, {}

    def test_auth_login(self):
        """Test user login with demo credentials"""
        self.log("=== Authentication Tests ===", "INFO")
        success, response = self.run_test(
            "Login", "POST", "/api/auth/login", 200,
            data={"email": "vikram@demo.com", "password": "password123"},
            description="Login with vikram@demo.com (Manager)"
        )
        if success and 'access_token' in response:
            self.token = response['access_token']
            self.user_info = response.get('user', {})
            self.log(f"Authenticated as: {self.user_info.get('name', 'Unknown')}")
            return True
        return False

    def test_auth_register(self):
        """Test user registration"""
        test_email = f"test_user_{datetime.now().strftime('%H%M%S')}@demo.com"
        success, response = self.run_test(
            "Register", "POST", "/api/auth/register", 200,
            data={
                "name": "Test User",
                "email": test_email,
                "phone": "9999999999",
                "password": "password123"
            },
            description="Register new user"
        )
        return success

    def test_societies_list(self):
        """Test society listing"""
        self.log("=== Society Tests ===", "INFO")
        success, response = self.run_test(
            "Society List", "GET", "/api/societies/", 200,
            description="List user societies"
        )
        if success and isinstance(response, list) and len(response) > 0:
            self.log(f"Found {len(response)} societies:")
            for soc in response:
                self.log(f"  - {soc['name']} (Role: {soc['role']})")
            
            # Look for Sunrise Apartments where vikram should be manager
            manager_society = None
            for soc in response:
                if soc['role'] == 'manager':
                    manager_society = soc
                    break
            
            if manager_society:
                self.society_id = manager_society['id']
                self.log(f"Selected society: {manager_society['name']} (Role: {manager_society['role']})")
                return True
            else:
                # Fallback to first society
                self.society_id = response[0]['id']
                self.log(f"No manager role found, using: {response[0]['name']} (Role: {response[0]['role']})")
                return True
        return False

    def test_society_dashboard(self):
        """Test society dashboard data"""
        if not self.society_id:
            self.log("SKIP - Dashboard test (no society selected)", "WARN")
            return False
        
        success, response = self.run_test(
            "Dashboard", "GET", f"/api/societies/{self.society_id}/dashboard", 200,
            description="Get financial dashboard data"
        )
        if success:
            self.log(f"Balance: Rs.{response.get('society_balance', 0):,}, Members: {response.get('member_count', 0)}")
        return success

    def test_transactions_list(self):
        """Test transactions listing"""
        self.log("=== Transaction Tests ===", "INFO")
        if not self.society_id:
            return False
        
        success, response = self.run_test(
            "Transaction List", "GET", f"/api/societies/{self.society_id}/transactions/", 200,
            description="List transactions"
        )
        return success

    def test_transaction_create(self):
        """Test creating a new transaction"""
        if not self.society_id:
            return False
        
        success, response = self.run_test(
            "Create Transaction", "POST", f"/api/societies/{self.society_id}/transactions/", 200,
            data={
                "type": "outward",
                "category": "Repairs & Maintenance",
                "amount": 5000,
                "description": "Test transaction - garden maintenance",
                "vendor_name": "Green Gardens Ltd",
                "payment_mode": "bank",
                "invoice_path": "",
                "date": datetime.now().strftime("%Y-%m-%d")
            },
            description="Create outward transaction"
        )
        return success

    def test_maintenance_bills(self):
        """Test maintenance bills listing"""
        self.log("=== Maintenance Tests ===", "INFO")
        if not self.society_id:
            return False
        
        success, response = self.run_test(
            "Maintenance Bills", "GET", f"/api/societies/{self.society_id}/maintenance/bills", 200,
            description="List maintenance bills"
        )
        return success

    def test_approvals_list(self):
        """Test approvals listing"""
        self.log("=== Approval Tests ===", "INFO")
        if not self.society_id:
            return False
        
        success, response = self.run_test(
            "Approvals List", "GET", f"/api/societies/{self.society_id}/approvals/", 200,
            description="List pending approvals"
        )
        return success

    def test_reports_endpoints(self):
        """Test all report endpoints"""
        self.log("=== Reports Tests ===", "INFO")
        if not self.society_id:
            return False
        
        endpoints = [
            ("Monthly Summary", f"/api/societies/{self.society_id}/reports/monthly-summary"),
            ("Category Spending", f"/api/societies/{self.society_id}/reports/category-spending"),
            ("Annual Summary", f"/api/societies/{self.society_id}/reports/annual-summary"),
        ]
        
        results = []
        for name, endpoint in endpoints:
            success, response = self.run_test(name, "GET", endpoint, 200, description=f"Get {name.lower()}")
            results.append(success)
        
        return all(results)

    def test_notifications(self):
        """Test notifications endpoint"""
        self.log("=== Notifications Tests ===", "INFO")
        success, response = self.run_test(
            "Notifications", "GET", "/api/notifications/", 200,
            description="List user notifications"
        )
        return success

    def test_transaction_categories(self):
        """Test transaction categories endpoint"""
        if not self.society_id:
            return False
        
        success, response = self.run_test(
            "Transaction Categories", "GET", f"/api/societies/{self.society_id}/transactions/categories", 200,
            description="Get transaction categories"
        )
        return success

    def run_all_tests(self):
        """Run complete test suite"""
        self.log("Starting Society Financial Management API Tests", "INFO")
        self.log(f"Base URL: {self.base_url}", "INFO")
        
        # Core authentication flow
        if not self.test_auth_login():
            self.log("CRITICAL: Login failed, stopping tests", "FAIL")
            return self.print_summary()
        
        # Test other auth
        self.test_auth_register()
        
        # Society tests
        if not self.test_societies_list():
            self.log("CRITICAL: Cannot get societies, stopping tests", "FAIL")
            return self.print_summary()
        
        # Dashboard and core features
        self.test_society_dashboard()
        self.test_transactions_list()
        self.test_transaction_create()
        self.test_transaction_categories()
        self.test_maintenance_bills()
        self.test_approvals_list()
        self.test_reports_endpoints()
        self.test_notifications()
        
        return self.print_summary()

    def print_summary(self):
        """Print test results summary"""
        self.log("=" * 50, "INFO")
        self.log("TEST SUMMARY", "INFO")
        self.log("=" * 50, "INFO")
        self.log(f"Total Tests: {self.tests_run}")
        self.log(f"Passed: {self.tests_passed}")
        self.log(f"Failed: {len(self.failed_tests)}")
        self.log(f"Success Rate: {(self.tests_passed/self.tests_run*100):.1f}%" if self.tests_run > 0 else "0%")
        
        if self.failed_tests:
            self.log("\n=== FAILED TESTS ===", "FAIL")
            for test in self.failed_tests:
                self.log(f"❌ {test['name']}")
                if 'endpoint' in test:
                    self.log(f"   Endpoint: {test['endpoint']}")
                if 'expected_status' in test:
                    self.log(f"   Expected: {test['expected_status']}, Got: {test['actual_status']}")
                if 'error' in test:
                    self.log(f"   Error: {test['error']}")
        
        # Return success status
        return self.tests_passed == self.tests_run

def main():
    tester = SocietyFinanceAPITester()
    success = tester.run_all_tests()
    return 0 if success else 1

if __name__ == "__main__":
    sys.exit(main())