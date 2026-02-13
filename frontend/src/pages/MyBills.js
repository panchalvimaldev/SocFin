import { useState, useEffect, useContext } from 'react';
import { useNavigate } from 'react-router-dom';
import { AuthContext } from '../context/AuthContext';
import { Card, CardContent, CardHeader, CardTitle } from '../components/ui/card';
import { Button } from '../components/ui/button';
import { Badge } from '../components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../components/ui/tabs';
import { toast } from 'sonner';
import { 
  Receipt, FileText, Download, CheckCircle2, Clock, 
  AlertTriangle, IndianRupee, Sparkles, Calendar, Building2 
} from 'lucide-react';

const API = process.env.REACT_APP_BACKEND_URL;

export default function MyBills() {
  const { token, currentSociety, user, role } = useContext(AuthContext);
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [bills, setBills] = useState([]);
  const [payments, setPayments] = useState([]);
  const [ledger, setLedger] = useState(null);
  const [schemes, setSchemes] = useState([]);
  const [annualPreview, setAnnualPreview] = useState(null);
  const [userFlat, setUserFlat] = useState(null);

  useEffect(() => {
    if (currentSociety?.id) {
      fetchUserFlat();
      fetchSchemes();
    }
  }, [currentSociety?.id]);

  useEffect(() => {
    if (userFlat) {
      fetchBills();
      fetchPayments();
      fetchLedger();
    }
  }, [userFlat]);

  const fetchUserFlat = async () => {
    try {
      const res = await fetch(`${API}/api/societies/${currentSociety.id}/flats`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (res.ok) {
        const flats = await res.json();
        // For members, we need to find their flat
        // In a real app, we'd have a proper endpoint for this
        if (flats.length > 0) {
          setUserFlat(flats[0]); // Simplified - would normally filter by user
        }
      }
    } catch (e) {
      console.error(e);
    }
  };

  const fetchBills = async () => {
    setLoading(true);
    try {
      const res = await fetch(
        `${API}/api/societies/${currentSociety.id}/maintenance/bills`,
        { headers: { Authorization: `Bearer ${token}` } }
      );
      if (res.ok) {
        const data = await res.json();
        setBills(data);
      }
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  const fetchPayments = async () => {
    try {
      const res = await fetch(
        `${API}/api/societies/${currentSociety.id}/maintenance/payments`,
        { headers: { Authorization: `Bearer ${token}` } }
      );
      if (res.ok) {
        const data = await res.json();
        setPayments(data);
      }
    } catch (e) {
      console.error(e);
    }
  };

  const fetchLedger = async () => {
    if (!userFlat) return;
    try {
      const res = await fetch(
        `${API}/api/societies/${currentSociety.id}/maintenance/ledger/${userFlat.id}`,
        { headers: { Authorization: `Bearer ${token}` } }
      );
      if (res.ok) {
        const data = await res.json();
        setLedger(data);
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

  const fetchAnnualPreview = async (schemeId) => {
    if (!userFlat) return;
    try {
      const res = await fetch(
        `${API}/api/societies/${currentSociety.id}/maintenance/annual-payment/preview`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            flat_id: userFlat.id,
            year: new Date().getFullYear(),
            discount_scheme_id: schemeId,
          }),
        }
      );
      if (res.ok) {
        const data = await res.json();
        setAnnualPreview(data);
      }
    } catch (e) {
      console.error(e);
    }
  };

  const downloadReceipt = async (paymentId) => {
    try {
      window.open(`${API}/api/societies/${currentSociety.id}/maintenance/receipts/${paymentId}/pdf`, '_blank');
    } catch (e) {
      toast.error('Failed to download receipt');
    }
  };

  const getStatusBadge = (status) => {
    switch (status) {
      case 'paid':
        return <Badge className="bg-emerald-500/20 text-emerald-400"><CheckCircle2 className="w-3 h-3 mr-1" />Paid</Badge>;
      case 'partial':
        return <Badge className="bg-cyan-500/20 text-cyan-400"><Clock className="w-3 h-3 mr-1" />Partial</Badge>;
      case 'overdue':
        return <Badge className="bg-red-500/20 text-red-400"><AlertTriangle className="w-3 h-3 mr-1" />Overdue</Badge>;
      default:
        return <Badge className="bg-amber-500/20 text-amber-400"><Clock className="w-3 h-3 mr-1" />Pending</Badge>;
    }
  };

  const pendingBills = bills.filter(b => b.status !== 'paid');
  const paidBills = bills.filter(b => b.status === 'paid');
  const totalPending = pendingBills.reduce((sum, b) => sum + (b.final_payable_amount - b.paid_amount), 0);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-cyan-400" />
      </div>
    );
  }

  return (
    <div className="space-y-6" data-testid="my-bills-page">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white">My Maintenance Bills</h1>
          <p className="text-slate-400 text-sm mt-1">View and track your maintenance payments</p>
        </div>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card className="bg-gradient-to-br from-amber-500/20 to-amber-600/10 border-amber-500/30">
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-amber-400 text-xs font-medium uppercase tracking-wider">Outstanding</p>
                <p className="text-3xl font-bold text-white mt-1">₹{totalPending.toLocaleString()}</p>
                <p className="text-amber-400 text-sm mt-1">{pendingBills.length} bills pending</p>
              </div>
              <IndianRupee className="w-10 h-10 text-amber-400 opacity-50" />
            </div>
          </CardContent>
        </Card>

        <Card className="bg-gradient-to-br from-emerald-500/20 to-emerald-600/10 border-emerald-500/30">
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-emerald-400 text-xs font-medium uppercase tracking-wider">Total Paid</p>
                <p className="text-3xl font-bold text-white mt-1">
                  ₹{payments.reduce((sum, p) => sum + p.amount_paid, 0).toLocaleString()}
                </p>
                <p className="text-emerald-400 text-sm mt-1">{payments.length} payments</p>
              </div>
              <CheckCircle2 className="w-10 h-10 text-emerald-400 opacity-50" />
            </div>
          </CardContent>
        </Card>

        {schemes.length > 0 && (
          <Card 
            className="bg-gradient-to-br from-purple-500/20 to-purple-600/10 border-purple-500/30 cursor-pointer hover:border-purple-400/50 transition-colors"
            onClick={() => fetchAnnualPreview(schemes[0].id)}
          >
            <CardContent className="pt-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-purple-400 text-xs font-medium uppercase tracking-wider">Pay Annual & Save</p>
                  <p className="text-lg font-bold text-white mt-1">{schemes[0].scheme_name}</p>
                  <p className="text-purple-400 text-sm mt-1">Click to view savings</p>
                </div>
                <Sparkles className="w-10 h-10 text-purple-400 opacity-50" />
              </div>
            </CardContent>
          </Card>
        )}
      </div>

      {/* Annual Payment Preview Modal/Card */}
      {annualPreview && (
        <Card className="bg-gradient-to-br from-purple-500/10 to-cyan-500/10 border-purple-500/30">
          <CardHeader>
            <CardTitle className="text-lg text-white flex items-center gap-2">
              <Sparkles className="w-5 h-5 text-purple-400" />
              Annual Payment Offer
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid md:grid-cols-2 gap-6">
              <div className="space-y-4">
                <div className="flex justify-between py-2 border-b border-slate-700">
                  <span className="text-slate-400">Flat</span>
                  <span className="text-white">{annualPreview.flat_number} ({annualPreview.area_sqft} sqft)</span>
                </div>
                <div className="flex justify-between py-2 border-b border-slate-700">
                  <span className="text-slate-400">Rate</span>
                  <span className="text-white">₹{annualPreview.rate_per_sqft}/sqft/month</span>
                </div>
                <div className="flex justify-between py-2 border-b border-slate-700">
                  <span className="text-slate-400">Monthly Amount</span>
                  <span className="text-white">₹{annualPreview.monthly_amount.toLocaleString()}</span>
                </div>
                <div className="flex justify-between py-2 border-b border-slate-700">
                  <span className="text-slate-400">12 Months Total</span>
                  <span className="text-white">₹{annualPreview.total_before_discount.toLocaleString()}</span>
                </div>
              </div>
              <div className="bg-purple-500/10 rounded-lg p-4 border border-purple-500/30">
                <div className="text-center">
                  <p className="text-purple-400 text-sm mb-2">With {annualPreview.discount_scheme_name}</p>
                  <p className="text-4xl font-bold text-white">₹{annualPreview.final_payable.toLocaleString()}</p>
                  <p className="text-emerald-400 text-lg mt-2">
                    Save ₹{annualPreview.discount_amount.toLocaleString()}
                  </p>
                  <p className="text-slate-400 text-sm mt-1">
                    {annualPreview.free_months} month(s) FREE!
                  </p>
                  {role === 'manager' && (
                    <Button 
                      className="mt-4 bg-purple-600 hover:bg-purple-700"
                      onClick={() => navigate('/payment-entry')}
                    >
                      Record Annual Payment
                    </Button>
                  )}
                </div>
              </div>
            </div>
            <Button 
              variant="ghost" 
              className="mt-4 text-slate-400"
              onClick={() => setAnnualPreview(null)}
            >
              Close
            </Button>
          </CardContent>
        </Card>
      )}

      <Tabs defaultValue="pending" className="space-y-6">
        <TabsList className="bg-slate-800/50 border border-slate-700">
          <TabsTrigger value="pending" className="data-[state=active]:bg-amber-500/20 data-[state=active]:text-amber-400">
            <Clock className="w-4 h-4 mr-2" />
            Pending ({pendingBills.length})
          </TabsTrigger>
          <TabsTrigger value="paid" className="data-[state=active]:bg-emerald-500/20 data-[state=active]:text-emerald-400">
            <CheckCircle2 className="w-4 h-4 mr-2" />
            Paid ({paidBills.length})
          </TabsTrigger>
          <TabsTrigger value="ledger" className="data-[state=active]:bg-cyan-500/20 data-[state=active]:text-cyan-400">
            <FileText className="w-4 h-4 mr-2" />
            Ledger
          </TabsTrigger>
          <TabsTrigger value="receipts" className="data-[state=active]:bg-purple-500/20 data-[state=active]:text-purple-400">
            <Receipt className="w-4 h-4 mr-2" />
            Receipts
          </TabsTrigger>
        </TabsList>

        <TabsContent value="pending">
          {pendingBills.length === 0 ? (
            <Card className="bg-slate-800/50 border-slate-700">
              <CardContent className="py-12 text-center">
                <CheckCircle2 className="w-12 h-12 text-emerald-400 mx-auto mb-4" />
                <p className="text-slate-400">No pending bills. You're all caught up!</p>
              </CardContent>
            </Card>
          ) : (
            <div className="space-y-3">
              {pendingBills.map((bill) => (
                <Card key={bill.id} className="bg-slate-800/50 border-slate-700">
                  <CardContent className="py-4">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-4">
                        <div className="w-12 h-12 rounded-lg bg-amber-500/20 flex items-center justify-center">
                          <Calendar className="w-6 h-6 text-amber-400" />
                        </div>
                        <div>
                          <p className="text-white font-medium">
                            {bill.bill_period_type === 'yearly' ? `Year ${bill.year}` : `${bill.month}/${bill.year}`}
                          </p>
                          <p className="text-slate-400 text-sm">Due: {bill.due_date}</p>
                          {bill.paid_amount > 0 && (
                            <p className="text-emerald-400 text-xs">₹{bill.paid_amount.toLocaleString()} paid</p>
                          )}
                        </div>
                      </div>
                      <div className="text-right">
                        <p className="text-2xl font-bold text-amber-400">
                          ₹{(bill.final_payable_amount - bill.paid_amount).toLocaleString()}
                        </p>
                        {getStatusBadge(bill.status)}
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}
        </TabsContent>

        <TabsContent value="paid">
          {paidBills.length === 0 ? (
            <Card className="bg-slate-800/50 border-slate-700">
              <CardContent className="py-12 text-center">
                <FileText className="w-12 h-12 text-slate-500 mx-auto mb-4" />
                <p className="text-slate-400">No paid bills yet</p>
              </CardContent>
            </Card>
          ) : (
            <div className="space-y-3">
              {paidBills.map((bill) => (
                <Card key={bill.id} className="bg-slate-800/50 border-slate-700">
                  <CardContent className="py-4">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-4">
                        <div className="w-12 h-12 rounded-lg bg-emerald-500/20 flex items-center justify-center">
                          <CheckCircle2 className="w-6 h-6 text-emerald-400" />
                        </div>
                        <div>
                          <p className="text-white font-medium">
                            {bill.bill_period_type === 'yearly' ? `Year ${bill.year}` : `${bill.month}/${bill.year}`}
                          </p>
                          <p className="text-slate-400 text-sm">{bill.flat_number}</p>
                        </div>
                      </div>
                      <div className="text-right">
                        <p className="text-xl font-bold text-emerald-400">
                          ₹{bill.final_payable_amount.toLocaleString()}
                        </p>
                        {getStatusBadge(bill.status)}
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}
        </TabsContent>

        <TabsContent value="ledger">
          {ledger ? (
            <Card className="bg-slate-800/50 border-slate-700">
              <CardHeader>
                <div className="flex items-center justify-between">
                  <CardTitle className="text-lg text-white">
                    Statement - {ledger.flat_number}
                  </CardTitle>
                  <Badge className={ledger.outstanding_balance > 0 ? 'bg-amber-500/20 text-amber-400' : 'bg-emerald-500/20 text-emerald-400'}>
                    Balance: ₹{ledger.outstanding_balance.toLocaleString()}
                  </Badge>
                </div>
              </CardHeader>
              <CardContent>
                <div className="overflow-x-auto">
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="border-b border-slate-700">
                        <th className="text-left py-2 text-slate-400">Date</th>
                        <th className="text-left py-2 text-slate-400">Description</th>
                        <th className="text-right py-2 text-slate-400">Debit</th>
                        <th className="text-right py-2 text-slate-400">Credit</th>
                        <th className="text-right py-2 text-slate-400">Balance</th>
                      </tr>
                    </thead>
                    <tbody>
                      {ledger.entries.map((entry) => (
                        <tr key={entry.id} className="border-b border-slate-700/50">
                          <td className="py-2 text-slate-300">{entry.entry_date.split('T')[0]}</td>
                          <td className="py-2 text-white">{entry.notes}</td>
                          <td className="py-2 text-right text-red-400">
                            {entry.debit_amount > 0 ? `₹${entry.debit_amount.toLocaleString()}` : '-'}
                          </td>
                          <td className="py-2 text-right text-emerald-400">
                            {entry.credit_amount > 0 ? `₹${entry.credit_amount.toLocaleString()}` : '-'}
                          </td>
                          <td className="py-2 text-right text-white font-medium">
                            ₹{entry.balance_after_entry.toLocaleString()}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </CardContent>
            </Card>
          ) : (
            <Card className="bg-slate-800/50 border-slate-700">
              <CardContent className="py-12 text-center">
                <FileText className="w-12 h-12 text-slate-500 mx-auto mb-4" />
                <p className="text-slate-400">No ledger data available</p>
              </CardContent>
            </Card>
          )}
        </TabsContent>

        <TabsContent value="receipts">
          {payments.length === 0 ? (
            <Card className="bg-slate-800/50 border-slate-700">
              <CardContent className="py-12 text-center">
                <Receipt className="w-12 h-12 text-slate-500 mx-auto mb-4" />
                <p className="text-slate-400">No payment receipts yet</p>
              </CardContent>
            </Card>
          ) : (
            <div className="space-y-3">
              {payments.map((payment) => (
                <Card key={payment.id} className="bg-slate-800/50 border-slate-700">
                  <CardContent className="py-4">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-4">
                        <div className="w-12 h-12 rounded-lg bg-purple-500/20 flex items-center justify-center">
                          <Receipt className="w-6 h-6 text-purple-400" />
                        </div>
                        <div>
                          <p className="text-white font-medium">{payment.receipt_number}</p>
                          <p className="text-slate-400 text-sm">{payment.payment_date}</p>
                          <Badge variant="outline" className="text-xs mt-1 border-slate-600 text-slate-400">
                            {payment.payment_mode.toUpperCase()}
                          </Badge>
                        </div>
                      </div>
                      <div className="flex items-center gap-4">
                        <div className="text-right">
                          <p className="text-xl font-bold text-emerald-400">
                            ₹{payment.amount_paid.toLocaleString()}
                          </p>
                          {payment.discount_applied > 0 && (
                            <p className="text-xs text-purple-400">
                              Saved ₹{payment.discount_applied.toLocaleString()}
                            </p>
                          )}
                        </div>
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => downloadReceipt(payment.id)}
                          className="border-slate-600 text-slate-300 hover:bg-slate-700"
                        >
                          <Download className="w-4 h-4 mr-1" />
                          Receipt
                        </Button>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}
        </TabsContent>
      </Tabs>
    </div>
  );
}
