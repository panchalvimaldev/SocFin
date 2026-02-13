"""
Backend API Tests for Society Financial Management Application
Tests: Authentication, Society CRUD, Members, Flats, Settings, Dashboard
"""
import pytest
import requests
import os

BASE_URL = os.environ.get('REACT_APP_BACKEND_URL', '').rstrip('/')


class TestHealthAndSeed:
    """Basic health check and seed data tests"""
    
    def test_api_root(self, api_client):
        """Test API root endpoint"""
        response = api_client.get(f"{BASE_URL}/api/")
        assert response.status_code == 200
        data = response.json()
        assert "message" in data
        assert "Society Financial Manager" in data["message"]
        print(f"✓ API root working: {data['message']}")

    def test_seed_data(self, api_client):
        """Test seed data endpoint"""
        response = api_client.post(f"{BASE_URL}/api/seed")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"
        assert data["data"]["users"] >= 4
        assert data["data"]["societies"] >= 2
        print(f"✓ Seed data created: {data['data']['users']} users, {data['data']['societies']} societies")


class TestAuthentication:
    """Authentication flow tests"""
    
    def test_login_manager_success(self, api_client, seed_data):
        """Test login with manager credentials (vikram@demo.com)"""
        response = api_client.post(f"{BASE_URL}/api/auth/login", json={
            "email": "vikram@demo.com",
            "password": "password123"
        })
        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data
        assert "user" in data
        assert data["user"]["email"] == "vikram@demo.com"
        assert data["user"]["name"] == "Vikram Sharma"
        print(f"✓ Manager login successful: {data['user']['name']}")
    
    def test_login_member_success(self, api_client, seed_data):
        """Test login with member credentials (priya@demo.com)"""
        response = api_client.post(f"{BASE_URL}/api/auth/login", json={
            "email": "priya@demo.com",
            "password": "password123"
        })
        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data
        assert data["user"]["email"] == "priya@demo.com"
        print(f"✓ Member login successful: {data['user']['name']}")
    
    def test_login_committee_success(self, api_client, seed_data):
        """Test login with committee credentials (rajesh@demo.com)"""
        response = api_client.post(f"{BASE_URL}/api/auth/login", json={
            "email": "rajesh@demo.com",
            "password": "password123"
        })
        assert response.status_code == 200
        data = response.json()
        assert data["user"]["email"] == "rajesh@demo.com"
        print(f"✓ Committee login successful: {data['user']['name']}")
    
    def test_login_auditor_success(self, api_client, seed_data):
        """Test login with auditor credentials (anita@demo.com)"""
        response = api_client.post(f"{BASE_URL}/api/auth/login", json={
            "email": "anita@demo.com",
            "password": "password123"
        })
        assert response.status_code == 200
        data = response.json()
        assert data["user"]["email"] == "anita@demo.com"
        print(f"✓ Auditor login successful: {data['user']['name']}")
    
    def test_login_invalid_credentials(self, api_client, seed_data):
        """Test login with invalid credentials"""
        response = api_client.post(f"{BASE_URL}/api/auth/login", json={
            "email": "wrong@example.com",
            "password": "wrongpass"
        })
        assert response.status_code == 401
        print("✓ Invalid credentials rejected correctly")
    
    def test_get_current_user(self, manager_client, manager_auth):
        """Test get current user endpoint"""
        response = manager_client.get(f"{BASE_URL}/api/auth/me")
        assert response.status_code == 200
        data = response.json()
        assert data["email"] == "vikram@demo.com"
        print(f"✓ Current user retrieved: {data['name']}")


class TestSocietyListing:
    """Society listing and switching tests"""
    
    def test_list_societies_manager(self, manager_client):
        """Test listing societies for manager user"""
        response = manager_client.get(f"{BASE_URL}/api/societies/")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) >= 2  # Vikram is in 2 societies
        
        # Check society structure
        society_names = [s["name"] for s in data]
        assert "Sunrise Apartments" in society_names
        assert "Green Valley Residency" in society_names
        
        # Check roles
        sunrise = next(s for s in data if s["name"] == "Sunrise Apartments")
        assert sunrise["role"] == "manager"
        
        green_valley = next(s for s in data if s["name"] == "Green Valley Residency")
        assert green_valley["role"] == "member"
        
        print(f"✓ Manager sees {len(data)} societies with correct roles")
        return sunrise["id"]
    
    def test_get_society_details(self, manager_client):
        """Test getting society details"""
        # First get society list
        list_response = manager_client.get(f"{BASE_URL}/api/societies/")
        societies = list_response.json()
        sunrise = next(s for s in societies if s["name"] == "Sunrise Apartments")
        
        # Get details
        response = manager_client.get(f"{BASE_URL}/api/societies/{sunrise['id']}")
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "Sunrise Apartments"
        assert data["address"] == "Sector 42, Gurugram, Haryana"
        assert data["total_flats"] == 440
        assert "approval_threshold" in data
        print(f"✓ Society details retrieved: {data['name']}")


class TestSocietySettings:
    """Society settings update tests (PUT /api/societies/{id})"""
    
    def test_update_society_settings_as_manager(self, manager_client):
        """Test updating society settings as manager"""
        # Get society ID
        list_response = manager_client.get(f"{BASE_URL}/api/societies/")
        societies = list_response.json()
        sunrise = next(s for s in societies if s["name"] == "Sunrise Apartments")
        society_id = sunrise["id"]
        
        # Update settings
        update_data = {
            "name": "Sunrise Apartments Updated",
            "address": "Sector 42, Gurugram, Haryana - Updated",
            "total_flats": 450,
            "description": "Updated description for testing",
            "approval_threshold": 75000
        }
        response = manager_client.put(f"{BASE_URL}/api/societies/{society_id}", json=update_data)
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "Sunrise Apartments Updated"
        assert data["total_flats"] == 450
        assert data["approval_threshold"] == 75000
        print(f"✓ Society settings updated successfully")
        
        # Verify persistence with GET
        get_response = manager_client.get(f"{BASE_URL}/api/societies/{society_id}")
        assert get_response.status_code == 200
        get_data = get_response.json()
        assert get_data["name"] == "Sunrise Apartments Updated"
        assert get_data["approval_threshold"] == 75000
        print(f"✓ Settings persisted correctly")
        
        # Restore original values
        restore_data = {
            "name": "Sunrise Apartments",
            "address": "Sector 42, Gurugram, Haryana",
            "total_flats": 440,
            "description": "Premium residential society with modern amenities",
            "approval_threshold": 50000
        }
        manager_client.put(f"{BASE_URL}/api/societies/{society_id}", json=restore_data)
    
    def test_update_society_partial(self, manager_client):
        """Test partial update of society settings"""
        list_response = manager_client.get(f"{BASE_URL}/api/societies/")
        societies = list_response.json()
        sunrise = next(s for s in societies if s["name"] == "Sunrise Apartments")
        society_id = sunrise["id"]
        
        # Only update threshold
        response = manager_client.put(f"{BASE_URL}/api/societies/{society_id}", json={
            "approval_threshold": 60000
        })
        assert response.status_code == 200
        data = response.json()
        assert data["approval_threshold"] == 60000
        assert data["name"] == "Sunrise Apartments"  # Other fields unchanged
        print(f"✓ Partial update works correctly")
        
        # Restore
        manager_client.put(f"{BASE_URL}/api/societies/{society_id}", json={"approval_threshold": 50000})
    
    def test_update_society_empty_fails(self, manager_client):
        """Test that empty update fails"""
        list_response = manager_client.get(f"{BASE_URL}/api/societies/")
        societies = list_response.json()
        sunrise = next(s for s in societies if s["name"] == "Sunrise Apartments")
        
        response = manager_client.put(f"{BASE_URL}/api/societies/{sunrise['id']}", json={})
        assert response.status_code == 400
        print(f"✓ Empty update rejected correctly")


class TestSocietyCreation:
    """Society creation tests"""
    
    def test_create_society(self, manager_client):
        """Test creating a new society"""
        create_data = {
            "name": "TEST_New Society",
            "address": "Test Address, Test City",
            "total_flats": 100,
            "description": "Test society for testing",
            "approval_threshold": 25000
        }
        response = manager_client.post(f"{BASE_URL}/api/societies/", json=create_data)
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "TEST_New Society"
        assert data["total_flats"] == 100
        assert "id" in data
        print(f"✓ Society created: {data['name']} with ID {data['id']}")
        
        # Verify user is now manager of this society
        list_response = manager_client.get(f"{BASE_URL}/api/societies/")
        societies = list_response.json()
        new_society = next((s for s in societies if s["name"] == "TEST_New Society"), None)
        assert new_society is not None
        assert new_society["role"] == "manager"
        print(f"✓ Creator is manager of new society")


class TestMembersManagement:
    """Members listing and management tests"""
    
    def test_list_society_members(self, manager_client):
        """Test listing society members"""
        list_response = manager_client.get(f"{BASE_URL}/api/societies/")
        societies = list_response.json()
        sunrise = next(s for s in societies if s["name"] == "Sunrise Apartments")
        
        response = manager_client.get(f"{BASE_URL}/api/societies/{sunrise['id']}/members")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) >= 4  # At least 4 members in Sunrise
        
        # Check member structure
        member = data[0]
        assert "id" in member
        assert "user_id" in member
        assert "role" in member
        assert "status" in member
        assert "user_name" in member
        assert "user_email" in member
        
        # Check roles exist
        roles = [m["role"] for m in data]
        assert "manager" in roles
        print(f"✓ Listed {len(data)} members with correct structure")
    
    def test_update_member_role(self, manager_client):
        """Test updating member role"""
        list_response = manager_client.get(f"{BASE_URL}/api/societies/")
        societies = list_response.json()
        sunrise = next(s for s in societies if s["name"] == "Sunrise Apartments")
        
        members_response = manager_client.get(f"{BASE_URL}/api/societies/{sunrise['id']}/members")
        members = members_response.json()
        
        # Find a member (not manager) to update
        member_to_update = next((m for m in members if m["role"] == "member"), None)
        if member_to_update:
            response = manager_client.put(
                f"{BASE_URL}/api/societies/{sunrise['id']}/members/{member_to_update['id']}?role=committee"
            )
            assert response.status_code == 200
            print(f"✓ Member role updated to committee")
            
            # Restore
            manager_client.put(
                f"{BASE_URL}/api/societies/{sunrise['id']}/members/{member_to_update['id']}?role=member"
            )


class TestFlatsManagement:
    """Flats listing and management tests"""
    
    def test_list_flats(self, manager_client):
        """Test listing society flats"""
        list_response = manager_client.get(f"{BASE_URL}/api/societies/")
        societies = list_response.json()
        sunrise = next(s for s in societies if s["name"] == "Sunrise Apartments")
        
        response = manager_client.get(f"{BASE_URL}/api/societies/{sunrise['id']}/flats")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) >= 10  # At least 10 flats
        
        # Check flat structure
        flat = data[0]
        assert "id" in flat
        assert "flat_number" in flat
        assert "floor" in flat
        assert "wing" in flat
        assert "area_sqft" in flat
        assert "flat_type" in flat
        print(f"✓ Listed {len(data)} flats with correct structure")
        return sunrise["id"], data[0]["id"]


class TestFlatMembersAssignment:
    """Flat-member assignment tests"""
    
    def test_list_flat_members(self, manager_client):
        """Test listing flat members"""
        list_response = manager_client.get(f"{BASE_URL}/api/societies/")
        societies = list_response.json()
        sunrise = next(s for s in societies if s["name"] == "Sunrise Apartments")
        
        flats_response = manager_client.get(f"{BASE_URL}/api/societies/{sunrise['id']}/flats")
        flats = flats_response.json()
        flat = flats[0]
        
        response = manager_client.get(f"{BASE_URL}/api/societies/{sunrise['id']}/flats/{flat['id']}/members")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        print(f"✓ Listed {len(data)} flat members for flat {flat['flat_number']}")
    
    def test_add_and_remove_flat_member(self, manager_client):
        """Test adding and removing flat member"""
        list_response = manager_client.get(f"{BASE_URL}/api/societies/")
        societies = list_response.json()
        sunrise = next(s for s in societies if s["name"] == "Sunrise Apartments")
        
        flats_response = manager_client.get(f"{BASE_URL}/api/societies/{sunrise['id']}/flats")
        flats = flats_response.json()
        flat = flats[5]  # Use a different flat
        
        members_response = manager_client.get(f"{BASE_URL}/api/societies/{sunrise['id']}/members")
        members = members_response.json()
        member = members[3]  # Pick a member
        
        # Add flat member
        add_response = manager_client.post(
            f"{BASE_URL}/api/societies/{sunrise['id']}/flats/{flat['id']}/members",
            json={
                "user_id": member["user_id"],
                "relation_type": "Tenant",
                "is_primary": False
            }
        )
        assert add_response.status_code == 200
        fm_data = add_response.json()
        assert fm_data["relation_type"] == "Tenant"
        print(f"✓ Added flat member: {fm_data['user_name']} as Tenant")
        
        # Remove flat member
        remove_response = manager_client.delete(
            f"{BASE_URL}/api/societies/{sunrise['id']}/flats/{flat['id']}/members/{fm_data['id']}"
        )
        assert remove_response.status_code == 200
        print(f"✓ Removed flat member successfully")


class TestDashboard:
    """Dashboard data tests"""
    
    def test_get_dashboard(self, manager_client):
        """Test getting dashboard data"""
        list_response = manager_client.get(f"{BASE_URL}/api/societies/")
        societies = list_response.json()
        sunrise = next(s for s in societies if s["name"] == "Sunrise Apartments")
        
        response = manager_client.get(f"{BASE_URL}/api/societies/{sunrise['id']}/dashboard")
        assert response.status_code == 200
        data = response.json()
        
        # Check dashboard structure
        assert "society_balance" in data
        assert "total_inward" in data
        assert "total_outward" in data
        assert "pending_dues" in data
        assert "pending_approvals" in data
        assert "recent_transactions" in data
        assert "monthly_trend" in data
        assert "member_count" in data
        assert "flat_count" in data
        
        print(f"✓ Dashboard data retrieved:")
        print(f"  Balance: Rs.{data['society_balance']:,.0f}")
        print(f"  Inward: Rs.{data['total_inward']:,.0f}")
        print(f"  Outward: Rs.{data['total_outward']:,.0f}")
        print(f"  Members: {data['member_count']}, Flats: {data['flat_count']}")


class TestMaintenanceLedger:
    """Maintenance and ledger tests"""
    
    def test_list_maintenance_bills(self, manager_client):
        """Test listing maintenance bills"""
        list_response = manager_client.get(f"{BASE_URL}/api/societies/")
        societies = list_response.json()
        sunrise = next(s for s in societies if s["name"] == "Sunrise Apartments")
        
        response = manager_client.get(f"{BASE_URL}/api/societies/{sunrise['id']}/maintenance/bills")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        print(f"✓ Listed {len(data)} maintenance bills")
    
    def test_get_flat_ledger(self, manager_client):
        """Test getting flat ledger"""
        list_response = manager_client.get(f"{BASE_URL}/api/societies/")
        societies = list_response.json()
        sunrise = next(s for s in societies if s["name"] == "Sunrise Apartments")
        
        flats_response = manager_client.get(f"{BASE_URL}/api/societies/{sunrise['id']}/flats")
        flats = flats_response.json()
        flat = flats[0]
        
        response = manager_client.get(f"{BASE_URL}/api/societies/{sunrise['id']}/maintenance/ledger/{flat['id']}")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        print(f"✓ Retrieved ledger for flat {flat['flat_number']}: {len(data)} entries")


class TestTransactions:
    """Transaction tests"""
    
    def test_list_transactions(self, manager_client):
        """Test listing transactions"""
        list_response = manager_client.get(f"{BASE_URL}/api/societies/")
        societies = list_response.json()
        sunrise = next(s for s in societies if s["name"] == "Sunrise Apartments")
        
        response = manager_client.get(f"{BASE_URL}/api/societies/{sunrise['id']}/transactions/")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) > 0
        print(f"✓ Listed {len(data)} transactions")
    
    def test_get_categories(self, manager_client):
        """Test getting transaction categories"""
        list_response = manager_client.get(f"{BASE_URL}/api/societies/")
        societies = list_response.json()
        sunrise = next(s for s in societies if s["name"] == "Sunrise Apartments")
        
        response = manager_client.get(f"{BASE_URL}/api/societies/{sunrise['id']}/transactions/categories")
        assert response.status_code == 200
        data = response.json()
        assert "inward" in data
        assert "outward" in data
        print(f"✓ Categories retrieved: {len(data['inward'])} inward, {len(data['outward'])} outward")


class TestApprovals:
    """Approval workflow tests"""
    
    def test_list_approvals(self, manager_client):
        """Test listing pending approvals"""
        list_response = manager_client.get(f"{BASE_URL}/api/societies/")
        societies = list_response.json()
        sunrise = next(s for s in societies if s["name"] == "Sunrise Apartments")
        
        response = manager_client.get(f"{BASE_URL}/api/societies/{sunrise['id']}/approvals/")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        print(f"✓ Listed {len(data)} approvals")


class TestNotifications:
    """Notification tests"""
    
    def test_list_notifications(self, manager_client):
        """Test listing user notifications"""
        response = manager_client.get(f"{BASE_URL}/api/notifications/")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        print(f"✓ Listed {len(data)} notifications")


class TestReports:
    """Reports tests"""
    
    def test_monthly_summary(self, manager_client):
        """Test monthly summary report"""
        list_response = manager_client.get(f"{BASE_URL}/api/societies/")
        societies = list_response.json()
        sunrise = next(s for s in societies if s["name"] == "Sunrise Apartments")
        
        response = manager_client.get(f"{BASE_URL}/api/societies/{sunrise['id']}/reports/monthly-summary?year=2026")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) > 0
        assert "total_inward" in data[0]
        assert "total_outward" in data[0]
        print(f"✓ Monthly summary retrieved: {len(data)} months")
    
    def test_category_spending(self, manager_client):
        """Test category spending report"""
        list_response = manager_client.get(f"{BASE_URL}/api/societies/")
        societies = list_response.json()
        sunrise = next(s for s in societies if s["name"] == "Sunrise Apartments")
        
        response = manager_client.get(f"{BASE_URL}/api/societies/{sunrise['id']}/reports/category-spending")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        print(f"✓ Category spending retrieved: {len(data)} categories")


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
