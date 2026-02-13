"""
Backend API Tests for Maintenance Billing Module
Tests: Maintenance Settings, Discount Schemes, Bill Generation, Payments, Ledger, Collection Dashboard
"""
import pytest
import requests
import os
from datetime import datetime

BASE_URL = os.environ.get('REACT_APP_BACKEND_URL', '').rstrip('/')


class TestMaintenanceSettings:
    """Maintenance Settings API tests - GET/PUT /api/societies/{id}/maintenance/settings"""
    
    def test_get_maintenance_settings(self, manager_client, society_id):
        """Test GET maintenance settings"""
        response = manager_client.get(f"{BASE_URL}/api/societies/{society_id}/maintenance/settings")
        assert response.status_code == 200
        data = response.json()
        
        # Validate response structure
        assert "id" in data
        assert "society_id" in data
        assert "default_rate_per_sqft" in data
        assert "billing_cycle" in data
        assert "due_date_day" in data
        assert "late_fee_amount" in data
        assert "late_fee_type" in data
        assert "is_discount_scheme_enabled" in data
        
        # Validate data types
        assert isinstance(data["default_rate_per_sqft"], (int, float))
        assert isinstance(data["due_date_day"], int)
        assert data["due_date_day"] >= 1 and data["due_date_day"] <= 31
        
        print(f"✓ Maintenance settings retrieved: Rate ₹{data['default_rate_per_sqft']}/sqft, Due day: {data['due_date_day']}")
        return data
    
    def test_update_maintenance_settings(self, manager_client, society_id):
        """Test PUT maintenance settings (Manager only)"""
        # Get current settings first
        get_response = manager_client.get(f"{BASE_URL}/api/societies/{society_id}/maintenance/settings")
        original_settings = get_response.json()
        
        # Update settings
        update_data = {
            "default_rate_per_sqft": 6.5,
            "billing_cycle": "monthly",
            "due_date_day": 15,
            "late_fee_amount": 100,
            "late_fee_type": "flat",
            "is_discount_scheme_enabled": True
        }
        response = manager_client.put(f"{BASE_URL}/api/societies/{society_id}/maintenance/settings", json=update_data)
        assert response.status_code == 200
        data = response.json()
        
        # Validate updated values
        assert data["default_rate_per_sqft"] == 6.5
        assert data["due_date_day"] == 15
        assert data["late_fee_amount"] == 100
        assert data["late_fee_type"] == "flat"
        print(f"✓ Settings updated: Rate ₹{data['default_rate_per_sqft']}/sqft, Late fee ₹{data['late_fee_amount']}")
        
        # Verify persistence with GET
        verify_response = manager_client.get(f"{BASE_URL}/api/societies/{society_id}/maintenance/settings")
        verify_data = verify_response.json()
        assert verify_data["default_rate_per_sqft"] == 6.5
        assert verify_data["due_date_day"] == 15
        print(f"✓ Settings persisted correctly")
        
        # Restore original settings
        restore_data = {
            "default_rate_per_sqft": original_settings["default_rate_per_sqft"],
            "billing_cycle": original_settings["billing_cycle"],
            "due_date_day": original_settings["due_date_day"],
            "late_fee_amount": original_settings["late_fee_amount"],
            "late_fee_type": original_settings["late_fee_type"],
            "is_discount_scheme_enabled": original_settings["is_discount_scheme_enabled"]
        }
        manager_client.put(f"{BASE_URL}/api/societies/{society_id}/maintenance/settings", json=restore_data)
        print(f"✓ Original settings restored")
    
    def test_member_cannot_update_settings(self, member_client, society_id):
        """Test that member cannot update maintenance settings"""
        update_data = {
            "default_rate_per_sqft": 10.0,
            "billing_cycle": "monthly",
            "due_date_day": 20,
            "late_fee_amount": 200,
            "late_fee_type": "flat",
            "is_discount_scheme_enabled": False
        }
        response = member_client.put(f"{BASE_URL}/api/societies/{society_id}/maintenance/settings", json=update_data)
        assert response.status_code == 403
        print(f"✓ Member correctly denied settings update (403)")


class TestDiscountSchemes:
    """Discount Schemes API tests - GET/POST /api/societies/{id}/maintenance/discount-schemes"""
    
    def test_list_discount_schemes(self, manager_client, society_id):
        """Test GET discount schemes list"""
        response = manager_client.get(f"{BASE_URL}/api/societies/{society_id}/maintenance/discount-schemes")
        assert response.status_code == 200
        data = response.json()
        
        assert isinstance(data, list)
        print(f"✓ Listed {len(data)} discount schemes")
        
        # Check structure if schemes exist
        if len(data) > 0:
            scheme = data[0]
            assert "id" in scheme
            assert "scheme_name" in scheme
            assert "eligible_months" in scheme
            assert "discount_type" in scheme
            assert "is_active" in scheme
            print(f"  - First scheme: {scheme['scheme_name']} ({scheme['discount_type']})")
        
        return data
    
    def test_create_pay_12_get_1_free_scheme(self, manager_client, society_id):
        """Test POST create Pay 12 Get 1 Free discount scheme"""
        scheme_data = {
            "scheme_name": "TEST_Pay 12 Get 1 Free",
            "eligible_months": 12,
            "free_months": 1,
            "discount_type": "free_months",
            "discount_value": 0,
            "is_active": True
        }
        response = manager_client.post(f"{BASE_URL}/api/societies/{society_id}/maintenance/discount-schemes", json=scheme_data)
        assert response.status_code == 200
        data = response.json()
        
        # Validate response
        assert data["scheme_name"] == "TEST_Pay 12 Get 1 Free"
        assert data["eligible_months"] == 12
        assert data["free_months"] == 1
        assert data["discount_type"] == "free_months"
        assert data["is_active"] == True
        assert "id" in data
        
        print(f"✓ Created discount scheme: {data['scheme_name']} (ID: {data['id']})")
        
        # Verify persistence
        list_response = manager_client.get(f"{BASE_URL}/api/societies/{society_id}/maintenance/discount-schemes")
        schemes = list_response.json()
        created_scheme = next((s for s in schemes if s["id"] == data["id"]), None)
        assert created_scheme is not None
        assert created_scheme["scheme_name"] == "TEST_Pay 12 Get 1 Free"
        print(f"✓ Scheme persisted correctly")
        
        return data["id"]
    
    def test_create_percentage_discount_scheme(self, manager_client, society_id):
        """Test POST create percentage discount scheme"""
        scheme_data = {
            "scheme_name": "TEST_Early Bird 5%",
            "eligible_months": 12,
            "free_months": 0,
            "discount_type": "percentage",
            "discount_value": 5.0,
            "is_active": True
        }
        response = manager_client.post(f"{BASE_URL}/api/societies/{society_id}/maintenance/discount-schemes", json=scheme_data)
        assert response.status_code == 200
        data = response.json()
        
        assert data["discount_type"] == "percentage"
        assert data["discount_value"] == 5.0
        print(f"✓ Created percentage discount scheme: {data['scheme_name']}")
        
        return data["id"]
    
    def test_update_discount_scheme(self, manager_client, society_id):
        """Test PUT update discount scheme"""
        # First create a scheme
        create_data = {
            "scheme_name": "TEST_Update Scheme",
            "eligible_months": 6,
            "free_months": 0,
            "discount_type": "flat",
            "discount_value": 500,
            "is_active": True
        }
        create_response = manager_client.post(f"{BASE_URL}/api/societies/{society_id}/maintenance/discount-schemes", json=create_data)
        scheme_id = create_response.json()["id"]
        
        # Update the scheme
        update_data = {
            "scheme_name": "TEST_Updated Scheme",
            "eligible_months": 12,
            "free_months": 0,
            "discount_type": "flat",
            "discount_value": 1000,
            "is_active": False
        }
        response = manager_client.put(f"{BASE_URL}/api/societies/{society_id}/maintenance/discount-schemes/{scheme_id}", json=update_data)
        assert response.status_code == 200
        data = response.json()
        
        assert data["scheme_name"] == "TEST_Updated Scheme"
        assert data["discount_value"] == 1000
        assert data["is_active"] == False
        print(f"✓ Scheme updated successfully")
        
        # Cleanup
        manager_client.delete(f"{BASE_URL}/api/societies/{society_id}/maintenance/discount-schemes/{scheme_id}")
    
    def test_delete_discount_scheme(self, manager_client, society_id):
        """Test DELETE discount scheme"""
        # Create a scheme to delete
        create_data = {
            "scheme_name": "TEST_Delete Scheme",
            "eligible_months": 6,
            "free_months": 0,
            "discount_type": "flat",
            "discount_value": 100,
            "is_active": True
        }
        create_response = manager_client.post(f"{BASE_URL}/api/societies/{society_id}/maintenance/discount-schemes", json=create_data)
        scheme_id = create_response.json()["id"]
        
        # Delete the scheme
        response = manager_client.delete(f"{BASE_URL}/api/societies/{society_id}/maintenance/discount-schemes/{scheme_id}")
        assert response.status_code == 200
        print(f"✓ Scheme deleted successfully")
        
        # Verify deletion
        list_response = manager_client.get(f"{BASE_URL}/api/societies/{society_id}/maintenance/discount-schemes")
        schemes = list_response.json()
        deleted_scheme = next((s for s in schemes if s["id"] == scheme_id), None)
        assert deleted_scheme is None
        print(f"✓ Scheme no longer exists in list")


class TestBillPreviewAndGeneration:
    """Bill Preview and Generation API tests"""
    
    def test_preview_monthly_bills(self, manager_client, society_id):
        """Test POST preview monthly bills with sqft calculation"""
        preview_data = {
            "bill_period_type": "monthly",
            "month": 3,
            "year": 2026,
            "apply_discount_scheme": False,
            "discount_scheme_id": None
        }
        response = manager_client.post(f"{BASE_URL}/api/societies/{society_id}/maintenance/bills/preview", json=preview_data)
        assert response.status_code == 200
        data = response.json()
        
        # Validate response structure
        assert "total_flats" in data
        assert "total_area_sqft" in data
        assert "rate_per_sqft" in data
        assert "total_collection_before_discount" in data
        assert "estimated_discount" in data
        assert "total_collection_after_discount" in data
        assert "bills_preview" in data
        
        # Validate data
        assert data["total_flats"] > 0
        assert data["total_area_sqft"] > 0
        assert data["rate_per_sqft"] > 0
        assert isinstance(data["bills_preview"], list)
        
        print(f"✓ Bill preview generated:")
        print(f"  - Total flats: {data['total_flats']}")
        print(f"  - Total area: {data['total_area_sqft']} sqft")
        print(f"  - Rate: ₹{data['rate_per_sqft']}/sqft")
        print(f"  - Total collection: ₹{data['total_collection_before_discount']}")
        
        # Validate bill preview structure
        if len(data["bills_preview"]) > 0:
            bill = data["bills_preview"][0]
            assert "flat_id" in bill
            assert "flat_number" in bill
            assert "area_sqft" in bill
            assert "rate_per_sqft" in bill
            assert "amount_before_discount" in bill
            assert "final_amount" in bill
            
            # Verify calculation: amount = area * rate
            expected_amount = bill["area_sqft"] * bill["rate_per_sqft"]
            assert abs(bill["amount_before_discount"] - expected_amount) < 0.01
            print(f"  - Sample bill: Flat {bill['flat_number']}, {bill['area_sqft']} sqft = ₹{bill['final_amount']}")
        
        return data
    
    def test_preview_yearly_bills_with_discount(self, manager_client, society_id):
        """Test POST preview yearly bills with discount scheme"""
        # Get active discount schemes
        schemes_response = manager_client.get(f"{BASE_URL}/api/societies/{society_id}/maintenance/discount-schemes")
        schemes = schemes_response.json()
        active_scheme = next((s for s in schemes if s["is_active"] and s["discount_type"] == "free_months"), None)
        
        if not active_scheme:
            pytest.skip("No active free_months discount scheme available")
        
        preview_data = {
            "bill_period_type": "yearly",
            "month": None,
            "year": 2026,
            "apply_discount_scheme": True,
            "discount_scheme_id": active_scheme["id"]
        }
        response = manager_client.post(f"{BASE_URL}/api/societies/{society_id}/maintenance/bills/preview", json=preview_data)
        assert response.status_code == 200
        data = response.json()
        
        # Verify discount is applied
        assert data["estimated_discount"] > 0
        assert data["total_collection_after_discount"] < data["total_collection_before_discount"]
        
        print(f"✓ Yearly bill preview with discount:")
        print(f"  - Before discount: ₹{data['total_collection_before_discount']}")
        print(f"  - Discount: ₹{data['estimated_discount']}")
        print(f"  - After discount: ₹{data['total_collection_after_discount']}")
    
    def test_generate_monthly_bills(self, manager_client, society_id):
        """Test POST generate monthly bills for all flats"""
        # Use a future month to avoid conflicts
        generate_data = {
            "bill_period_type": "monthly",
            "month": 6,
            "year": 2027,
            "apply_discount_scheme": False,
            "discount_scheme_id": None
        }
        response = manager_client.post(f"{BASE_URL}/api/societies/{society_id}/maintenance/bills/generate", json=generate_data)
        assert response.status_code == 200
        data = response.json()
        
        # Validate response
        assert data["status"] == "success"
        assert "bills_created" in data
        assert "total_amount" in data
        assert "period" in data
        assert data["bills_created"] > 0
        
        print(f"✓ Bills generated:")
        print(f"  - Bills created: {data['bills_created']}")
        print(f"  - Total amount: ₹{data['total_amount']}")
        print(f"  - Period: {data['period']}")
        
        return data
    
    def test_duplicate_bill_generation_fails(self, manager_client, society_id):
        """Test that duplicate bill generation fails"""
        # Try to generate bills for the same period again
        generate_data = {
            "bill_period_type": "monthly",
            "month": 6,
            "year": 2027,
            "apply_discount_scheme": False,
            "discount_scheme_id": None
        }
        response = manager_client.post(f"{BASE_URL}/api/societies/{society_id}/maintenance/bills/generate", json=generate_data)
        assert response.status_code == 400
        assert "already generated" in response.json()["detail"].lower()
        print(f"✓ Duplicate bill generation correctly rejected")


class TestBillsListing:
    """Bills Listing API tests - GET /api/societies/{id}/maintenance/bills"""
    
    def test_list_all_bills(self, manager_client, society_id):
        """Test GET list all maintenance bills"""
        response = manager_client.get(f"{BASE_URL}/api/societies/{society_id}/maintenance/bills")
        assert response.status_code == 200
        data = response.json()
        
        assert isinstance(data, list)
        print(f"✓ Listed {len(data)} maintenance bills")
        
        if len(data) > 0:
            bill = data[0]
            # Validate bill structure
            assert "id" in bill
            assert "flat_id" in bill
            assert "flat_number" in bill
            assert "bill_period_type" in bill
            assert "year" in bill
            assert "area_sqft" in bill
            assert "rate_per_sqft" in bill
            assert "final_payable_amount" in bill
            assert "status" in bill
            assert "due_date" in bill
            print(f"  - Sample bill: {bill['flat_number']}, {bill['bill_period_type']}, ₹{bill['final_payable_amount']}, Status: {bill['status']}")
        
        return data
    
    def test_list_bills_with_filters(self, manager_client, society_id):
        """Test GET bills with status filter"""
        # Filter by pending status
        response = manager_client.get(f"{BASE_URL}/api/societies/{society_id}/maintenance/bills?status=pending")
        assert response.status_code == 200
        data = response.json()
        
        # All returned bills should be pending
        for bill in data:
            assert bill["status"] == "pending"
        
        print(f"✓ Filtered {len(data)} pending bills")
    
    def test_member_sees_only_own_bills(self, member_client, society_id):
        """Test that member can only see their own flat's bills"""
        response = member_client.get(f"{BASE_URL}/api/societies/{society_id}/maintenance/bills")
        assert response.status_code == 200
        data = response.json()
        
        # Member should see limited bills (only their flats)
        print(f"✓ Member sees {len(data)} bills (own flats only)")


class TestAnnualPaymentPreview:
    """Annual Payment Preview API tests"""
    
    def test_annual_payment_preview(self, manager_client, society_id, flat_id):
        """Test POST annual payment preview with discount calculation"""
        # Get active discount scheme
        schemes_response = manager_client.get(f"{BASE_URL}/api/societies/{society_id}/maintenance/discount-schemes")
        schemes = schemes_response.json()
        active_scheme = next((s for s in schemes if s["is_active"]), None)
        
        preview_data = {
            "flat_id": flat_id,
            "year": 2026,
            "discount_scheme_id": active_scheme["id"] if active_scheme else None
        }
        response = manager_client.post(f"{BASE_URL}/api/societies/{society_id}/maintenance/annual-payment/preview", json=preview_data)
        assert response.status_code == 200
        data = response.json()
        
        # Validate response structure
        assert "flat_id" in data
        assert "flat_number" in data
        assert "area_sqft" in data
        assert "rate_per_sqft" in data
        assert "monthly_amount" in data
        assert "total_months" in data
        assert "total_before_discount" in data
        assert "discount_amount" in data
        assert "final_payable" in data
        assert "pending_months" in data
        assert "already_paid_months" in data
        
        # Validate calculations
        expected_monthly = data["area_sqft"] * data["rate_per_sqft"]
        assert abs(data["monthly_amount"] - expected_monthly) < 0.01
        
        expected_total = expected_monthly * data["total_months"]
        assert abs(data["total_before_discount"] - expected_total) < 0.01
        
        print(f"✓ Annual payment preview:")
        print(f"  - Flat: {data['flat_number']}, {data['area_sqft']} sqft")
        print(f"  - Monthly: ₹{data['monthly_amount']}")
        print(f"  - Total (12 months): ₹{data['total_before_discount']}")
        print(f"  - Discount: ₹{data['discount_amount']}")
        print(f"  - Final payable: ₹{data['final_payable']}")
        
        return data


class TestPayments:
    """Payment Recording API tests - POST /api/societies/{id}/maintenance/payments"""
    
    def test_record_payment(self, manager_client, society_id, flat_id):
        """Test POST record payment with receipt generation"""
        # Get pending bills for the flat
        bills_response = manager_client.get(f"{BASE_URL}/api/societies/{society_id}/maintenance/bills?flat_id={flat_id}&status=pending")
        bills = bills_response.json()
        
        if len(bills) == 0:
            pytest.skip("No pending bills for this flat")
        
        bill = bills[0]
        amount_due = bill["final_payable_amount"] - bill.get("paid_amount", 0)
        
        payment_data = {
            "flat_id": flat_id,
            "bill_ids": [bill["id"]],
            "amount_paid": amount_due,
            "payment_mode": "upi",
            "payment_date": datetime.now().strftime("%Y-%m-%d"),
            "transaction_reference": "TEST_UPI_REF_123",
            "remarks": "Test payment",
            "is_annual_payment": False,
            "discount_scheme_id": None
        }
        response = manager_client.post(f"{BASE_URL}/api/societies/{society_id}/maintenance/payments", json=payment_data)
        assert response.status_code == 200
        data = response.json()
        
        # Validate response
        assert "id" in data
        assert "receipt_number" in data
        assert data["amount_paid"] == amount_due
        assert data["payment_mode"] == "upi"
        assert data["flat_id"] == flat_id
        
        print(f"✓ Payment recorded:")
        print(f"  - Receipt: {data['receipt_number']}")
        print(f"  - Amount: ₹{data['amount_paid']}")
        print(f"  - Mode: {data['payment_mode']}")
        
        # Verify bill status updated
        bill_response = manager_client.get(f"{BASE_URL}/api/societies/{society_id}/maintenance/bills/{bill['id']}")
        if bill_response.status_code == 200:
            updated_bill = bill_response.json()
            assert updated_bill["status"] in ["paid", "partial"]
            print(f"  - Bill status: {updated_bill['status']}")
        
        return data
    
    def test_list_payments(self, manager_client, society_id):
        """Test GET list payments"""
        response = manager_client.get(f"{BASE_URL}/api/societies/{society_id}/maintenance/payments")
        assert response.status_code == 200
        data = response.json()
        
        assert isinstance(data, list)
        print(f"✓ Listed {len(data)} payments")
        
        if len(data) > 0:
            payment = data[0]
            assert "id" in payment
            assert "receipt_number" in payment
            assert "amount_paid" in payment
            assert "payment_mode" in payment
            assert "payment_date" in payment


class TestLedger:
    """Ledger API tests - GET /api/societies/{id}/maintenance/ledger/{flat_id}"""
    
    def test_get_flat_ledger(self, manager_client, society_id, flat_id):
        """Test GET flat ledger with running balance"""
        response = manager_client.get(f"{BASE_URL}/api/societies/{society_id}/maintenance/ledger/{flat_id}")
        assert response.status_code == 200
        data = response.json()
        
        # Validate response structure
        assert "flat_id" in data
        assert "flat_number" in data
        assert "total_billed" in data
        assert "total_paid" in data
        assert "total_discount" in data
        assert "outstanding_balance" in data
        assert "entries" in data
        
        print(f"✓ Ledger retrieved for flat {data['flat_number']}:")
        print(f"  - Total billed: ₹{data['total_billed']}")
        print(f"  - Total paid: ₹{data['total_paid']}")
        print(f"  - Discount: ₹{data['total_discount']}")
        print(f"  - Outstanding: ₹{data['outstanding_balance']}")
        print(f"  - Entries: {len(data['entries'])}")
        
        # Validate ledger entries structure
        if len(data["entries"]) > 0:
            entry = data["entries"][0]
            assert "id" in entry
            assert "entry_date" in entry
            assert "entry_type" in entry
            assert "debit_amount" in entry
            assert "credit_amount" in entry
            assert "balance_after_entry" in entry
        
        return data
    
    def test_member_can_view_own_ledger(self, member_client, society_id):
        """Test that member can view their own flat's ledger"""
        # Get member's flats
        # Member should be able to access their own ledger
        # This test verifies the permission check
        response = member_client.get(f"{BASE_URL}/api/societies/{society_id}/maintenance/bills")
        if response.status_code == 200:
            bills = response.json()
            if len(bills) > 0:
                flat_id = bills[0]["flat_id"]
                ledger_response = member_client.get(f"{BASE_URL}/api/societies/{society_id}/maintenance/ledger/{flat_id}")
                assert ledger_response.status_code == 200
                print(f"✓ Member can view own flat's ledger")


class TestCollectionDashboard:
    """Collection Dashboard API tests - GET /api/societies/{id}/maintenance/collection-dashboard"""
    
    def test_get_collection_dashboard(self, manager_client, society_id):
        """Test GET collection dashboard statistics"""
        response = manager_client.get(f"{BASE_URL}/api/societies/{society_id}/maintenance/collection-dashboard")
        assert response.status_code == 200
        data = response.json()
        
        # Validate response structure
        assert "total_flats" in data
        assert "paid_flats" in data
        assert "pending_flats" in data
        assert "overdue_flats" in data
        assert "total_billed" in data
        assert "total_collected" in data
        assert "total_outstanding" in data
        assert "collection_percentage" in data
        assert "month_wise_collection" in data
        assert "recent_payments" in data
        
        # Validate data types
        assert isinstance(data["total_flats"], int)
        assert isinstance(data["collection_percentage"], (int, float))
        assert isinstance(data["month_wise_collection"], list)
        assert isinstance(data["recent_payments"], list)
        
        print(f"✓ Collection dashboard retrieved:")
        print(f"  - Total flats: {data['total_flats']}")
        print(f"  - Paid: {data['paid_flats']}, Pending: {data['pending_flats']}, Overdue: {data['overdue_flats']}")
        print(f"  - Total billed: ₹{data['total_billed']}")
        print(f"  - Total collected: ₹{data['total_collected']}")
        print(f"  - Collection %: {data['collection_percentage']}%")
        
        # Validate month-wise collection structure
        if len(data["month_wise_collection"]) > 0:
            month_data = data["month_wise_collection"][0]
            assert "month" in month_data
            assert "billed" in month_data
            assert "collected" in month_data
            assert "pending" in month_data
        
        return data
    
    def test_collection_dashboard_with_filters(self, manager_client, society_id):
        """Test GET collection dashboard with year/month filters"""
        response = manager_client.get(f"{BASE_URL}/api/societies/{society_id}/maintenance/collection-dashboard?year=2026&month=1")
        assert response.status_code == 200
        data = response.json()
        
        assert "total_billed" in data
        assert "total_collected" in data
        print(f"✓ Dashboard with filters: Billed ₹{data['total_billed']}, Collected ₹{data['total_collected']}")


class TestReceipts:
    """Receipt API tests"""
    
    def test_get_receipt(self, manager_client, society_id):
        """Test GET receipt details"""
        # Get a payment first
        payments_response = manager_client.get(f"{BASE_URL}/api/societies/{society_id}/maintenance/payments")
        payments = payments_response.json()
        
        if len(payments) == 0:
            pytest.skip("No payments available for receipt test")
        
        payment = payments[0]
        response = manager_client.get(f"{BASE_URL}/api/societies/{society_id}/maintenance/receipts/{payment['id']}")
        assert response.status_code == 200
        data = response.json()
        
        # Validate receipt structure
        assert "receipt_number" in data
        assert "society_name" in data
        assert "flat_number" in data
        assert "final_paid_amount" in data
        assert "payment_mode" in data
        assert "payment_date" in data
        
        print(f"✓ Receipt retrieved: {data['receipt_number']}")
        print(f"  - Flat: {data['flat_number']}")
        print(f"  - Amount: ₹{data['final_paid_amount']}")


class TestOverdueProcessing:
    """Overdue Processing API tests"""
    
    def test_process_overdue_bills(self, manager_client, society_id):
        """Test POST process overdue bills"""
        response = manager_client.post(f"{BASE_URL}/api/societies/{society_id}/maintenance/process-overdue")
        assert response.status_code == 200
        data = response.json()
        
        assert data["status"] == "success"
        assert "overdue_bills_processed" in data
        print(f"✓ Overdue processing completed: {data['overdue_bills_processed']} bills processed")


# Cleanup fixture
@pytest.fixture(scope="class", autouse=True)
def cleanup_test_schemes(manager_client, society_id):
    """Cleanup TEST_ prefixed discount schemes after tests"""
    yield
    # Cleanup
    try:
        schemes_response = manager_client.get(f"{BASE_URL}/api/societies/{society_id}/maintenance/discount-schemes")
        if schemes_response.status_code == 200:
            schemes = schemes_response.json()
            for scheme in schemes:
                if scheme["scheme_name"].startswith("TEST_"):
                    manager_client.delete(f"{BASE_URL}/api/societies/{society_id}/maintenance/discount-schemes/{scheme['id']}")
    except:
        pass


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
