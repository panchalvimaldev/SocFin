import { useState, useEffect, useContext } from 'react';
import { AuthContext } from '@/contexts/AuthContext';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Button } from '@/components/ui/button';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Switch } from '@/components/ui/switch';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Badge } from '@/components/ui/badge';
import { toast } from 'sonner';
import { Settings, Save, Plus, Trash2, Percent, Tag, Calendar } from 'lucide-react';

const API = process.env.REACT_APP_BACKEND_URL;

export default function MaintenanceSettings() {
  const { token, currentSociety, role } = useContext(AuthContext);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  
  // Settings state
  const [settings, setSettings] = useState({
    default_rate_per_sqft: 5,
    billing_cycle: 'monthly',
    due_date_day: 10,
    late_fee_amount: 0,
    late_fee_type: 'flat',
    is_discount_scheme_enabled: true,
  });
  
  // Discount schemes state
  const [schemes, setSchemes] = useState([]);
  const [newScheme, setNewScheme] = useState({
    scheme_name: '',
    eligible_months: 12,
    free_months: 1,
    discount_type: 'free_months',
    discount_value: 0,
    is_active: true,
  });

  useEffect(() => {
    if (currentSociety?.id) {
      fetchSettings();
      fetchSchemes();
    }
  }, [currentSociety?.id]);

  const fetchSettings = async () => {
    try {
      const res = await fetch(`${API}/api/societies/${currentSociety.id}/maintenance/settings`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (res.ok) {
        const data = await res.json();
        setSettings(data);
      }
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  const fetchSchemes = async () => {
    try {
      const res = await fetch(`${API}/api/societies/${currentSociety.id}/maintenance/discount-schemes`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (res.ok) {
        const data = await res.json();
        setSchemes(data);
      }
    } catch (e) {
      console.error(e);
    }
  };

  const saveSettings = async () => {
    setSaving(true);
    try {
      const res = await fetch(`${API}/api/societies/${currentSociety.id}/maintenance/settings`, {
        method: 'PUT',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(settings),
      });
      if (res.ok) {
        toast.success('Settings saved successfully');
      } else {
        toast.error('Failed to save settings');
      }
    } catch (e) {
      toast.error('Error saving settings');
    } finally {
      setSaving(false);
    }
  };

  const createScheme = async () => {
    if (!newScheme.scheme_name) {
      toast.error('Please enter scheme name');
      return;
    }
    
    try {
      const res = await fetch(`${API}/api/societies/${currentSociety.id}/maintenance/discount-schemes`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(newScheme),
      });
      if (res.ok) {
        toast.success('Discount scheme created');
        fetchSchemes();
        setNewScheme({
          scheme_name: '',
          eligible_months: 12,
          free_months: 1,
          discount_type: 'free_months',
          discount_value: 0,
          is_active: true,
        });
      } else {
        toast.error('Failed to create scheme');
      }
    } catch (e) {
      toast.error('Error creating scheme');
    }
  };

  const deleteScheme = async (schemeId) => {
    if (!window.confirm('Delete this discount scheme?')) return;
    
    try {
      const res = await fetch(
        `${API}/api/societies/${currentSociety.id}/maintenance/discount-schemes/${schemeId}`,
        {
          method: 'DELETE',
          headers: { Authorization: `Bearer ${token}` },
        }
      );
      if (res.ok) {
        toast.success('Scheme deleted');
        fetchSchemes();
      } else {
        toast.error('Failed to delete scheme');
      }
    } catch (e) {
      toast.error('Error deleting scheme');
    }
  };

  const toggleSchemeActive = async (scheme) => {
    try {
      const res = await fetch(
        `${API}/api/societies/${currentSociety.id}/maintenance/discount-schemes/${scheme.id}`,
        {
          method: 'PUT',
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ ...scheme, is_active: !scheme.is_active }),
        }
      );
      if (res.ok) {
        fetchSchemes();
      }
    } catch (e) {
      console.error(e);
    }
  };

  const isManager = role === 'manager';

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-cyan-400" />
      </div>
    );
  }

  return (
    <div className="space-y-6" data-testid="maintenance-settings-page">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white">Maintenance Settings</h1>
          <p className="text-slate-400 text-sm mt-1">Configure billing rates and discount schemes</p>
        </div>
      </div>

      <Tabs defaultValue="settings" className="space-y-6">
        <TabsList className="bg-slate-800/50 border border-slate-700">
          <TabsTrigger value="settings" className="data-[state=active]:bg-cyan-500/20 data-[state=active]:text-cyan-400">
            <Settings className="w-4 h-4 mr-2" />
            Rate Settings
          </TabsTrigger>
          <TabsTrigger value="discounts" className="data-[state=active]:bg-cyan-500/20 data-[state=active]:text-cyan-400">
            <Percent className="w-4 h-4 mr-2" />
            Discount Schemes
          </TabsTrigger>
        </TabsList>

        <TabsContent value="settings">
          <div className="grid gap-6 md:grid-cols-2">
            {/* Billing Rate Card */}
            <Card className="bg-slate-800/50 border-slate-700">
              <CardHeader>
                <CardTitle className="text-lg text-white flex items-center gap-2">
                  <Tag className="w-5 h-5 text-cyan-400" />
                  Billing Rate
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div>
                  <Label className="text-slate-300">Rate per Square Foot (₹)</Label>
                  <Input
                    type="number"
                    step="0.5"
                    value={settings.default_rate_per_sqft}
                    onChange={(e) => setSettings({ ...settings, default_rate_per_sqft: parseFloat(e.target.value) || 0 })}
                    disabled={!isManager}
                    className="bg-slate-900 border-slate-600 text-white mt-1"
                    data-testid="rate-per-sqft-input"
                  />
                  <p className="text-xs text-slate-500 mt-1">
                    Example: 1000 sqft flat = ₹{(settings.default_rate_per_sqft * 1000).toLocaleString()}/month
                  </p>
                </div>

                <div>
                  <Label className="text-slate-300">Billing Cycle</Label>
                  <Select
                    value={settings.billing_cycle}
                    onValueChange={(v) => setSettings({ ...settings, billing_cycle: v })}
                    disabled={!isManager}
                  >
                    <SelectTrigger className="bg-slate-900 border-slate-600 text-white mt-1">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent className="bg-slate-800 border-slate-700">
                      <SelectItem value="monthly">Monthly</SelectItem>
                      <SelectItem value="quarterly">Quarterly</SelectItem>
                      <SelectItem value="yearly">Yearly</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div>
                  <Label className="text-slate-300">Due Date (Day of Month)</Label>
                  <Input
                    type="number"
                    min="1"
                    max="28"
                    value={settings.due_date_day}
                    onChange={(e) => setSettings({ ...settings, due_date_day: parseInt(e.target.value) || 10 })}
                    disabled={!isManager}
                    className="bg-slate-900 border-slate-600 text-white mt-1"
                  />
                </div>
              </CardContent>
            </Card>

            {/* Late Fee Card */}
            <Card className="bg-slate-800/50 border-slate-700">
              <CardHeader>
                <CardTitle className="text-lg text-white flex items-center gap-2">
                  <Calendar className="w-5 h-5 text-amber-400" />
                  Late Fee Configuration
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div>
                  <Label className="text-slate-300">Late Fee Type</Label>
                  <Select
                    value={settings.late_fee_type}
                    onValueChange={(v) => setSettings({ ...settings, late_fee_type: v })}
                    disabled={!isManager}
                  >
                    <SelectTrigger className="bg-slate-900 border-slate-600 text-white mt-1">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent className="bg-slate-800 border-slate-700">
                      <SelectItem value="flat">Flat Amount (₹)</SelectItem>
                      <SelectItem value="percentage">Percentage (%)</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div>
                  <Label className="text-slate-300">
                    Late Fee {settings.late_fee_type === 'percentage' ? '(%)' : '(₹)'}
                  </Label>
                  <Input
                    type="number"
                    value={settings.late_fee_amount}
                    onChange={(e) => setSettings({ ...settings, late_fee_amount: parseFloat(e.target.value) || 0 })}
                    disabled={!isManager}
                    className="bg-slate-900 border-slate-600 text-white mt-1"
                  />
                  <p className="text-xs text-slate-500 mt-1">
                    Applied to overdue bills after due date
                  </p>
                </div>

                <div className="flex items-center justify-between pt-4 border-t border-slate-700">
                  <div>
                    <Label className="text-slate-300">Enable Discount Schemes</Label>
                    <p className="text-xs text-slate-500">Allow members to pay annually with discount</p>
                  </div>
                  <Switch
                    checked={settings.is_discount_scheme_enabled}
                    onCheckedChange={(v) => setSettings({ ...settings, is_discount_scheme_enabled: v })}
                    disabled={!isManager}
                  />
                </div>
              </CardContent>
            </Card>
          </div>

          {isManager && (
            <div className="flex justify-end mt-6">
              <Button
                onClick={saveSettings}
                disabled={saving}
                className="bg-cyan-600 hover:bg-cyan-700"
                data-testid="save-settings-btn"
              >
                <Save className="w-4 h-4 mr-2" />
                {saving ? 'Saving...' : 'Save Settings'}
              </Button>
            </div>
          )}
        </TabsContent>

        <TabsContent value="discounts">
          <div className="grid gap-6 lg:grid-cols-2">
            {/* Existing Schemes */}
            <Card className="bg-slate-800/50 border-slate-700">
              <CardHeader>
                <CardTitle className="text-lg text-white">Active Discount Schemes</CardTitle>
              </CardHeader>
              <CardContent>
                {schemes.length === 0 ? (
                  <p className="text-slate-400 text-center py-8">No discount schemes configured</p>
                ) : (
                  <div className="space-y-3">
                    {schemes.map((scheme) => (
                      <div
                        key={scheme.id}
                        className="p-4 bg-slate-900/50 rounded-lg border border-slate-700 flex items-center justify-between"
                      >
                        <div>
                          <div className="flex items-center gap-2">
                            <span className="font-medium text-white">{scheme.scheme_name}</span>
                            <Badge variant={scheme.is_active ? 'default' : 'secondary'} className={scheme.is_active ? 'bg-emerald-500/20 text-emerald-400' : 'bg-slate-600'}>
                              {scheme.is_active ? 'Active' : 'Inactive'}
                            </Badge>
                          </div>
                          <p className="text-sm text-slate-400 mt-1">
                            Pay {scheme.eligible_months} months → 
                            {scheme.discount_type === 'free_months' && ` Get ${scheme.free_months} month(s) free`}
                            {scheme.discount_type === 'percentage' && ` ${scheme.discount_value}% off`}
                            {scheme.discount_type === 'flat' && ` ₹${scheme.discount_value} off`}
                          </p>
                        </div>
                        {isManager && (
                          <div className="flex items-center gap-2">
                            <Switch
                              checked={scheme.is_active}
                              onCheckedChange={() => toggleSchemeActive(scheme)}
                            />
                            <Button
                              variant="ghost"
                              size="icon"
                              onClick={() => deleteScheme(scheme.id)}
                              className="text-red-400 hover:text-red-300 hover:bg-red-500/10"
                            >
                              <Trash2 className="w-4 h-4" />
                            </Button>
                          </div>
                        )}
                      </div>
                    ))}
                  </div>
                )}
              </CardContent>
            </Card>

            {/* Create New Scheme */}
            {isManager && (
              <Card className="bg-slate-800/50 border-slate-700">
                <CardHeader>
                  <CardTitle className="text-lg text-white flex items-center gap-2">
                    <Plus className="w-5 h-5 text-cyan-400" />
                    Create New Scheme
                  </CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div>
                    <Label className="text-slate-300">Scheme Name</Label>
                    <Input
                      placeholder="e.g., Pay 12 Get 1 Free"
                      value={newScheme.scheme_name}
                      onChange={(e) => setNewScheme({ ...newScheme, scheme_name: e.target.value })}
                      className="bg-slate-900 border-slate-600 text-white mt-1"
                      data-testid="new-scheme-name"
                    />
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <Label className="text-slate-300">Eligible Months</Label>
                      <Input
                        type="number"
                        value={newScheme.eligible_months}
                        onChange={(e) => setNewScheme({ ...newScheme, eligible_months: parseInt(e.target.value) || 12 })}
                        className="bg-slate-900 border-slate-600 text-white mt-1"
                      />
                    </div>
                    <div>
                      <Label className="text-slate-300">Discount Type</Label>
                      <Select
                        value={newScheme.discount_type}
                        onValueChange={(v) => setNewScheme({ ...newScheme, discount_type: v })}
                      >
                        <SelectTrigger className="bg-slate-900 border-slate-600 text-white mt-1">
                          <SelectValue />
                        </SelectTrigger>
                        <SelectContent className="bg-slate-800 border-slate-700">
                          <SelectItem value="free_months">Free Months</SelectItem>
                          <SelectItem value="percentage">Percentage Off</SelectItem>
                          <SelectItem value="flat">Flat Discount</SelectItem>
                        </SelectContent>
                      </Select>
                    </div>
                  </div>

                  {newScheme.discount_type === 'free_months' ? (
                    <div>
                      <Label className="text-slate-300">Free Months</Label>
                      <Input
                        type="number"
                        value={newScheme.free_months}
                        onChange={(e) => setNewScheme({ ...newScheme, free_months: parseInt(e.target.value) || 1 })}
                        className="bg-slate-900 border-slate-600 text-white mt-1"
                      />
                    </div>
                  ) : (
                    <div>
                      <Label className="text-slate-300">
                        Discount Value {newScheme.discount_type === 'percentage' ? '(%)' : '(₹)'}
                      </Label>
                      <Input
                        type="number"
                        value={newScheme.discount_value}
                        onChange={(e) => setNewScheme({ ...newScheme, discount_value: parseFloat(e.target.value) || 0 })}
                        className="bg-slate-900 border-slate-600 text-white mt-1"
                      />
                    </div>
                  )}

                  <Button
                    onClick={createScheme}
                    className="w-full bg-cyan-600 hover:bg-cyan-700"
                    data-testid="create-scheme-btn"
                  >
                    <Plus className="w-4 h-4 mr-2" />
                    Create Scheme
                  </Button>
                </CardContent>
              </Card>
            )}
          </div>
        </TabsContent>
      </Tabs>
    </div>
  );
}
