import { useState, useEffect, useContext } from 'react';
import { AuthContext } from '@/contexts/AuthContext';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { Badge } from '@/components/ui/badge';
import { toast } from 'sonner';
import { FileText, Calculator, Sparkles, Building2, IndianRupee, AlertCircle } from 'lucide-react';

const API = process.env.REACT_APP_BACKEND_URL;

export default function GenerateBills() {
  const { token, currentSociety, role } = useContext(AuthContext);
  const [loading, setLoading] = useState(false);
  const [generating, setGenerating] = useState(false);
  const [settings, setSettings] = useState(null);
  const [schemes, setSchemes] = useState([]);
  const [preview, setPreview] = useState(null);
  
  // Form state
  const [billPeriodType, setBillPeriodType] = useState('monthly');
  const [month, setMonth] = useState(new Date().getMonth() + 1);
  const [year, setYear] = useState(new Date().getFullYear());
  const [applyDiscount, setApplyDiscount] = useState(false);
  const [selectedScheme, setSelectedScheme] = useState('');

  const months = [
    { value: 1, label: 'January' }, { value: 2, label: 'February' },
    { value: 3, label: 'March' }, { value: 4, label: 'April' },
    { value: 5, label: 'May' }, { value: 6, label: 'June' },
    { value: 7, label: 'July' }, { value: 8, label: 'August' },
    { value: 9, label: 'September' }, { value: 10, label: 'October' },
    { value: 11, label: 'November' }, { value: 12, label: 'December' },
  ];

  useEffect(() => {
    if (currentSociety?.id) {
      fetchSettings();
      fetchSchemes();
    }
  }, [currentSociety?.id]);

  useEffect(() => {
    if (settings) {
      fetchPreview();
    }
  }, [billPeriodType, month, year, applyDiscount, selectedScheme, settings]);

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
    }
  };

  const fetchSchemes = async () => {
    try {
      const res = await fetch(`${API}/api/societies/${currentSociety.id}/maintenance/discount-schemes`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (res.ok) {
        const data = await res.json();
        setSchemes(data.filter(s => s.is_active));
      }
    } catch (e) {
      console.error(e);
    }
  };

  const fetchPreview = async () => {
    setLoading(true);
    try {
      const body = {
        bill_period_type: billPeriodType,
        month: billPeriodType === 'monthly' ? month : null,
        year,
        apply_discount_scheme: applyDiscount && billPeriodType === 'yearly',
        discount_scheme_id: applyDiscount && billPeriodType === 'yearly' ? selectedScheme : null,
      };
      
      const res = await fetch(`${API}/api/societies/${currentSociety.id}/maintenance/bills/preview`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(body),
      });
      if (res.ok) {
        const data = await res.json();
        setPreview(data);
      }
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  const generateBills = async () => {
    if (!window.confirm(`Generate ${billPeriodType} bills for ${billPeriodType === 'monthly' ? `${months.find(m => m.value === month)?.label} ` : ''}${year}?`)) {
      return;
    }
    
    setGenerating(true);
    try {
      const body = {
        bill_period_type: billPeriodType,
        month: billPeriodType === 'monthly' ? month : null,
        year,
        apply_discount_scheme: applyDiscount && billPeriodType === 'yearly',
        discount_scheme_id: applyDiscount && billPeriodType === 'yearly' ? selectedScheme : null,
      };
      
      const res = await fetch(`${API}/api/societies/${currentSociety.id}/maintenance/bills/generate`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(body),
      });
      
      const data = await res.json();
      
      if (res.ok) {
        toast.success(`${data.bills_created} bills generated successfully!`);
        fetchPreview();
      } else {
        toast.error(data.detail || 'Failed to generate bills');
      }
    } catch (e) {
      toast.error('Error generating bills');
    } finally {
      setGenerating(false);
    }
  };

  if (role !== 'manager') {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-center">
          <AlertCircle className="w-12 h-12 text-amber-400 mx-auto mb-4" />
          <p className="text-slate-400">Only managers can generate bills</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6" data-testid="generate-bills-page">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white">Generate Maintenance Bills</h1>
          <p className="text-slate-400 text-sm mt-1">Create bills for all flats based on square footage</p>
        </div>
      </div>

      <div className="grid gap-6 lg:grid-cols-3">
        {/* Configuration */}
        <Card className="bg-slate-800/50 border-slate-700 lg:col-span-1">
          <CardHeader>
            <CardTitle className="text-lg text-white flex items-center gap-2">
              <Calculator className="w-5 h-5 text-cyan-400" />
              Bill Configuration
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div>
              <Label className="text-slate-300">Bill Period Type</Label>
              <Select value={billPeriodType} onValueChange={setBillPeriodType}>
                <SelectTrigger className="bg-slate-900 border-slate-600 text-white mt-1">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent className="bg-slate-800 border-slate-700">
                  <SelectItem value="monthly">Monthly Bill</SelectItem>
                  <SelectItem value="yearly">Annual Bill</SelectItem>
                </SelectContent>
              </Select>
            </div>

            {billPeriodType === 'monthly' && (
              <div>
                <Label className="text-slate-300">Month</Label>
                <Select value={String(month)} onValueChange={(v) => setMonth(parseInt(v))}>
                  <SelectTrigger className="bg-slate-900 border-slate-600 text-white mt-1">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent className="bg-slate-800 border-slate-700">
                    {months.map((m) => (
                      <SelectItem key={m.value} value={String(m.value)}>
                        {m.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            )}

            <div>
              <Label className="text-slate-300">Year</Label>
              <Select value={String(year)} onValueChange={(v) => setYear(parseInt(v))}>
                <SelectTrigger className="bg-slate-900 border-slate-600 text-white mt-1">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent className="bg-slate-800 border-slate-700">
                  <SelectItem value="2025">2025</SelectItem>
                  <SelectItem value="2026">2026</SelectItem>
                  <SelectItem value="2027">2027</SelectItem>
                </SelectContent>
              </Select>
            </div>

            {billPeriodType === 'yearly' && schemes.length > 0 && (
              <>
                <div className="flex items-center justify-between pt-4 border-t border-slate-700">
                  <div>
                    <Label className="text-slate-300">Apply Discount Scheme</Label>
                    <p className="text-xs text-slate-500">For annual payments</p>
                  </div>
                  <Switch checked={applyDiscount} onCheckedChange={setApplyDiscount} />
                </div>

                {applyDiscount && (
                  <div>
                    <Label className="text-slate-300">Select Scheme</Label>
                    <Select value={selectedScheme} onValueChange={setSelectedScheme}>
                      <SelectTrigger className="bg-slate-900 border-slate-600 text-white mt-1">
                        <SelectValue placeholder="Choose discount scheme" />
                      </SelectTrigger>
                      <SelectContent className="bg-slate-800 border-slate-700">
                        {schemes.map((s) => (
                          <SelectItem key={s.id} value={s.id}>
                            {s.scheme_name}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                )}
              </>
            )}

            {settings && (
              <div className="p-3 bg-slate-900/50 rounded-lg border border-slate-700 mt-4">
                <p className="text-xs text-slate-400 mb-2">Current Rate</p>
                <p className="text-lg font-bold text-cyan-400">
                  ₹{settings.default_rate_per_sqft} <span className="text-sm font-normal text-slate-400">per sqft</span>
                </p>
                <p className="text-xs text-slate-500 mt-1">
                  Due on {settings.due_date_day}th of each month
                </p>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Preview */}
        <Card className="bg-slate-800/50 border-slate-700 lg:col-span-2">
          <CardHeader>
            <CardTitle className="text-lg text-white flex items-center gap-2">
              <FileText className="w-5 h-5 text-emerald-400" />
              Bill Preview
            </CardTitle>
          </CardHeader>
          <CardContent>
            {loading ? (
              <div className="flex items-center justify-center h-48">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-cyan-400" />
              </div>
            ) : preview ? (
              <div className="space-y-6">
                {/* Summary Cards */}
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                  <div className="p-4 bg-slate-900/50 rounded-lg border border-slate-700">
                    <div className="flex items-center gap-2 text-slate-400 text-xs mb-1">
                      <Building2 className="w-3 h-3" />
                      Total Flats
                    </div>
                    <p className="text-2xl font-bold text-white">{preview.total_flats}</p>
                  </div>
                  <div className="p-4 bg-slate-900/50 rounded-lg border border-slate-700">
                    <div className="text-slate-400 text-xs mb-1">Total Area</div>
                    <p className="text-2xl font-bold text-white">{preview.total_area_sqft.toLocaleString()}</p>
                    <p className="text-xs text-slate-500">sqft</p>
                  </div>
                  <div className="p-4 bg-slate-900/50 rounded-lg border border-slate-700">
                    <div className="text-slate-400 text-xs mb-1">Total Collection</div>
                    <p className="text-2xl font-bold text-cyan-400">
                      ₹{preview.total_collection_before_discount.toLocaleString()}
                    </p>
                    {preview.estimated_discount > 0 && (
                      <p className="text-xs text-emerald-400">-₹{preview.estimated_discount.toLocaleString()} discount</p>
                    )}
                  </div>
                  <div className="p-4 bg-emerald-500/10 rounded-lg border border-emerald-500/30">
                    <div className="flex items-center gap-2 text-emerald-400 text-xs mb-1">
                      <Sparkles className="w-3 h-3" />
                      Net Collection
                    </div>
                    <p className="text-2xl font-bold text-emerald-400">
                      ₹{preview.total_collection_after_discount.toLocaleString()}
                    </p>
                  </div>
                </div>

                {/* Bills Table */}
                <div className="overflow-x-auto">
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="border-b border-slate-700">
                        <th className="text-left py-2 text-slate-400 font-medium">Flat</th>
                        <th className="text-left py-2 text-slate-400 font-medium">Wing</th>
                        <th className="text-right py-2 text-slate-400 font-medium">Area</th>
                        <th className="text-right py-2 text-slate-400 font-medium">Amount</th>
                        {preview.estimated_discount > 0 && (
                          <th className="text-right py-2 text-slate-400 font-medium">Discount</th>
                        )}
                        <th className="text-right py-2 text-slate-400 font-medium">Final</th>
                        <th className="text-left py-2 text-slate-400 font-medium">Owner</th>
                      </tr>
                    </thead>
                    <tbody>
                      {preview.bills_preview.slice(0, 10).map((bill, idx) => (
                        <tr key={idx} className="border-b border-slate-700/50">
                          <td className="py-2 text-white font-medium">{bill.flat_number}</td>
                          <td className="py-2 text-slate-400">{bill.wing}</td>
                          <td className="py-2 text-right text-slate-300">{bill.area_sqft}</td>
                          <td className="py-2 text-right text-slate-300">₹{bill.amount_before_discount.toLocaleString()}</td>
                          {preview.estimated_discount > 0 && (
                            <td className="py-2 text-right text-emerald-400">
                              {bill.discount > 0 ? `-₹${bill.discount.toLocaleString()}` : '-'}
                            </td>
                          )}
                          <td className="py-2 text-right text-cyan-400 font-medium">₹{bill.final_amount.toLocaleString()}</td>
                          <td className="py-2 text-slate-400">{bill.primary_user || '-'}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                  {preview.bills_preview.length > 10 && (
                    <p className="text-center text-slate-500 text-sm py-2">
                      ...and {preview.bills_preview.length - 10} more flats
                    </p>
                  )}
                </div>

                {/* Generate Button */}
                <div className="flex justify-end pt-4 border-t border-slate-700">
                  <Button
                    onClick={generateBills}
                    disabled={generating}
                    className="bg-emerald-600 hover:bg-emerald-700"
                    data-testid="generate-bills-btn"
                  >
                    <FileText className="w-4 h-4 mr-2" />
                    {generating ? 'Generating...' : `Generate ${preview.total_flats} Bills`}
                  </Button>
                </div>
              </div>
            ) : (
              <div className="text-center text-slate-400 py-12">
                Select billing period to preview
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
