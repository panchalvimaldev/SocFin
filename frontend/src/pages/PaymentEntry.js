import { useState, useEffect } from "react";
import { useSociety } from "@/contexts/SocietyContext";
import api from "@/lib/api";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Button } from "@/components/ui/button";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Checkbox } from "@/components/ui/checkbox";
import { Badge } from "@/components/ui/badge";
import { toast } from "sonner";
import { CreditCard, Building2, IndianRupee, Receipt, Check, Sparkles } from "lucide-react";

export default function PaymentEntry() {
  const { currentSociety, role } = useSociety();
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  
  const [flats, setFlats] = useState([]);
  const [bills, setBills] = useState([]);
  const [schemes, setSchemes] = useState([]);
  const [annualPreview, setAnnualPreview] = useState(null);
  
  const [selectedFlat, setSelectedFlat] = useState("");
  const [selectedBills, setSelectedBills] = useState([]);
  const [paymentMode, setPaymentMode] = useState("upi");
  const [transactionRef, setTransactionRef] = useState("");
  const [remarks, setRemarks] = useState("");
  const [isAnnualPayment, setIsAnnualPayment] = useState(false);
  const [selectedScheme, setSelectedScheme] = useState("");
  const [customAmount, setCustomAmount] = useState("");

  useEffect(() => {
    if (currentSociety?.id) {
      fetchFlats();
      fetchSchemes();
    }
  }, [currentSociety?.id]);

  useEffect(() => {
    if (selectedFlat) {
      fetchBills(selectedFlat);
      if (isAnnualPayment && selectedScheme) fetchAnnualPreview();
    } else {
      setBills([]);
      setAnnualPreview(null);
    }
  }, [selectedFlat]);

  useEffect(() => {
    if (isAnnualPayment && selectedFlat && selectedScheme) {
      fetchAnnualPreview();
    } else {
      setAnnualPreview(null);
    }
  }, [isAnnualPayment, selectedScheme, selectedFlat]);

  const fetchFlats = async () => {
    try {
      const res = await api.get(`/societies/${currentSociety.id}/flats`);
      setFlats(res.data);
    } catch (e) { console.error(e); } finally { setLoading(false); }
  };

  const fetchBills = async (flatId) => {
    try {
      const res = await api.get(`/societies/${currentSociety.id}/maintenance/bills?flat_id=${flatId}&status=pending`);
      setBills(res.data);
    } catch (e) { console.error(e); }
  };

  const fetchSchemes = async () => {
    try {
      const res = await api.get(`/societies/${currentSociety.id}/maintenance/discount-schemes`);
      setSchemes(res.data.filter(s => s.is_active));
    } catch (e) { console.error(e); }
  };

  const fetchAnnualPreview = async () => {
    try {
      const res = await api.post(`/societies/${currentSociety.id}/maintenance/annual-payment/preview`, {
        flat_id: selectedFlat,
        year: new Date().getFullYear(),
        discount_scheme_id: selectedScheme,
      });
      setAnnualPreview(res.data);
    } catch (e) { console.error(e); }
  };

  const toggleBillSelection = (billId) => {
    setSelectedBills(prev => prev.includes(billId) ? prev.filter(id => id !== billId) : [...prev, billId]);
  };

  const calculateTotal = () => {
    if (customAmount) return parseFloat(customAmount);
    if (isAnnualPayment && annualPreview) return annualPreview.final_payable;
    return selectedBills.reduce((sum, billId) => {
      const bill = bills.find(b => b.id === billId);
      return sum + (bill ? bill.final_payable_amount - bill.paid_amount : 0);
    }, 0);
  };

  const handleSubmit = async () => {
    if (!selectedFlat) { toast.error("Please select a flat"); return; }
    const amount = calculateTotal();
    if (amount <= 0) { toast.error("Please enter a valid amount"); return; }
    
    setSubmitting(true);
    try {
      const payload = {
        flat_id: selectedFlat,
        bill_ids: isAnnualPayment ? [] : selectedBills,
        amount_paid: amount,
        payment_mode: paymentMode,
        payment_date: new Date().toISOString().split("T")[0],
        transaction_reference: transactionRef,
        remarks,
        is_annual_payment: isAnnualPayment,
        discount_scheme_id: isAnnualPayment ? selectedScheme : null,
      };
      const res = await api.post(`/societies/${currentSociety.id}/maintenance/payments`, payload);
      toast.success(`Payment recorded! Receipt: ${res.data.receipt_number}`);
      setSelectedFlat(""); setSelectedBills([]); setTransactionRef(""); setRemarks(""); setCustomAmount(""); setBills([]); setAnnualPreview(null);
    } catch (e) {
      toast.error(e.response?.data?.detail || "Failed to record payment");
    } finally { setSubmitting(false); }
  };

  if (role !== "manager") {
    return <div className="flex items-center justify-center h-64"><p className="text-slate-400">Only managers can record payments</p></div>;
  }

  const selectedFlatData = flats.find(f => f.id === selectedFlat);

  return (
    <div className="space-y-6" data-testid="payment-entry-page">
      <div>
        <h1 className="text-2xl font-bold text-white">Record Payment</h1>
        <p className="text-slate-400 text-sm mt-1">Enter maintenance payment details</p>
      </div>

      <div className="grid gap-6 lg:grid-cols-3">
        <Card className="bg-slate-800/50 border-slate-700 lg:col-span-2">
          <CardHeader>
            <CardTitle className="text-lg text-white flex items-center gap-2"><CreditCard className="w-5 h-5 text-cyan-400" />Payment Details</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div>
              <Label className="text-slate-300">Select Flat</Label>
              <Select value={selectedFlat} onValueChange={setSelectedFlat}>
                <SelectTrigger className="bg-slate-900 border-slate-600 text-white mt-1"><SelectValue placeholder="Choose flat" /></SelectTrigger>
                <SelectContent className="bg-slate-800 border-slate-700 max-h-[300px]">
                  {flats.map((flat) => <SelectItem key={flat.id} value={flat.id}>{flat.flat_number} - {flat.wing} Wing ({flat.area_sqft} sqft)</SelectItem>)}
                </SelectContent>
              </Select>
            </div>

            {selectedFlat && (
              <>
                <div className="flex items-center gap-4 p-4 bg-slate-900/50 rounded-lg border border-slate-700">
                  <Button variant={!isAnnualPayment ? "default" : "outline"} onClick={() => setIsAnnualPayment(false)} className={!isAnnualPayment ? "bg-cyan-600" : "border-slate-600"}>Monthly Bills</Button>
                  <Button variant={isAnnualPayment ? "default" : "outline"} onClick={() => setIsAnnualPayment(true)} className={isAnnualPayment ? "bg-emerald-600" : "border-slate-600"}><Sparkles className="w-4 h-4 mr-2" />Annual Payment</Button>
                </div>

                {!isAnnualPayment && (
                  <div>
                    <Label className="text-slate-300 mb-2 block">Pending Bills</Label>
                    {bills.length === 0 ? (
                      <p className="text-slate-400 text-sm p-4 bg-slate-900/50 rounded-lg">No pending bills for this flat</p>
                    ) : (
                      <div className="space-y-2 max-h-[200px] overflow-y-auto">
                        {bills.map((bill) => (
                          <div key={bill.id} className={`flex items-center gap-3 p-3 rounded-lg border cursor-pointer transition-colors ${selectedBills.includes(bill.id) ? "bg-cyan-500/20 border-cyan-500/50" : "bg-slate-900/50 border-slate-700 hover:border-slate-600"}`} onClick={() => toggleBillSelection(bill.id)}>
                            <Checkbox checked={selectedBills.includes(bill.id)} onCheckedChange={() => toggleBillSelection(bill.id)} />
                            <div className="flex-1">
                              <p className="text-white font-medium">{bill.month}/{bill.year} - {bill.bill_period_type}</p>
                              <p className="text-xs text-slate-400">Due: {bill.due_date}</p>
                              {bill.paid_amount > 0 && <p className="text-xs text-emerald-400">₹{bill.paid_amount.toLocaleString()} paid</p>}
                            </div>
                            <div className="text-right">
                              <p className="text-cyan-400 font-bold">₹{(bill.final_payable_amount - bill.paid_amount).toLocaleString()}</p>
                            </div>
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                )}

                {isAnnualPayment && schemes.length > 0 && (
                  <div>
                    <Label className="text-slate-300">Discount Scheme</Label>
                    <Select value={selectedScheme} onValueChange={setSelectedScheme}>
                      <SelectTrigger className="bg-slate-900 border-slate-600 text-white mt-1"><SelectValue placeholder="Select scheme" /></SelectTrigger>
                      <SelectContent className="bg-slate-800 border-slate-700">
                        {schemes.map((scheme) => <SelectItem key={scheme.id} value={scheme.id}>{scheme.scheme_name}</SelectItem>)}
                      </SelectContent>
                    </Select>
                  </div>
                )}

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <Label className="text-slate-300">Payment Mode</Label>
                    <Select value={paymentMode} onValueChange={setPaymentMode}>
                      <SelectTrigger className="bg-slate-900 border-slate-600 text-white mt-1"><SelectValue /></SelectTrigger>
                      <SelectContent className="bg-slate-800 border-slate-700">
                        <SelectItem value="upi">UPI</SelectItem>
                        <SelectItem value="bank">Bank Transfer</SelectItem>
                        <SelectItem value="cash">Cash</SelectItem>
                        <SelectItem value="cheque">Cheque</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                  <div>
                    <Label className="text-slate-300">Transaction Reference</Label>
                    <Input placeholder="UPI ID / Cheque No." value={transactionRef} onChange={(e) => setTransactionRef(e.target.value)} className="bg-slate-900 border-slate-600 text-white mt-1" />
                  </div>
                </div>

                <div>
                  <Label className="text-slate-300">Custom Amount (optional)</Label>
                  <Input type="number" placeholder="Leave empty to use calculated amount" value={customAmount} onChange={(e) => setCustomAmount(e.target.value)} className="bg-slate-900 border-slate-600 text-white mt-1" />
                </div>

                <div>
                  <Label className="text-slate-300">Remarks</Label>
                  <Input placeholder="Additional notes" value={remarks} onChange={(e) => setRemarks(e.target.value)} className="bg-slate-900 border-slate-600 text-white mt-1" />
                </div>
              </>
            )}
          </CardContent>
        </Card>

        <Card className="bg-slate-800/50 border-slate-700">
          <CardHeader><CardTitle className="text-lg text-white flex items-center gap-2"><Receipt className="w-5 h-5 text-emerald-400" />Payment Summary</CardTitle></CardHeader>
          <CardContent className="space-y-4">
            {selectedFlatData && (
              <div className="p-4 bg-slate-900/50 rounded-lg border border-slate-700">
                <div className="flex items-center gap-3 mb-3">
                  <Building2 className="w-8 h-8 text-cyan-400" />
                  <div>
                    <p className="text-white font-bold text-lg">{selectedFlatData.flat_number}</p>
                    <p className="text-slate-400 text-sm">{selectedFlatData.wing} Wing • {selectedFlatData.area_sqft} sqft</p>
                  </div>
                </div>
              </div>
            )}

            {isAnnualPayment && annualPreview && (
              <div className="space-y-3 p-4 bg-emerald-500/10 rounded-lg border border-emerald-500/30">
                <div className="flex justify-between"><span className="text-slate-400">Annual Total</span><span className="text-white">₹{annualPreview.total_before_discount.toLocaleString()}</span></div>
                {annualPreview.discount_amount > 0 && <div className="flex justify-between"><span className="text-emerald-400">Discount ({annualPreview.free_months} months free)</span><span className="text-emerald-400">-₹{annualPreview.discount_amount.toLocaleString()}</span></div>}
                <div className="flex justify-between pt-3 border-t border-emerald-500/30"><span className="text-white font-bold">Final Payable</span><span className="text-emerald-400 font-bold text-xl">₹{annualPreview.final_payable.toLocaleString()}</span></div>
              </div>
            )}

            {!isAnnualPayment && selectedBills.length > 0 && (
              <div className="space-y-2">
                <div className="flex justify-between"><span className="text-slate-400">Selected Bills</span><Badge className="bg-cyan-500/20 text-cyan-400">{selectedBills.length}</Badge></div>
                <div className="flex justify-between pt-2 border-t border-slate-700"><span className="text-white font-bold">Total</span><span className="text-cyan-400 font-bold text-xl">₹{calculateTotal().toLocaleString()}</span></div>
              </div>
            )}

            {customAmount && <div className="p-3 bg-amber-500/10 rounded-lg border border-amber-500/30"><p className="text-amber-400 text-sm">Custom amount will override calculated total</p></div>}

            <Button onClick={handleSubmit} disabled={submitting || (!customAmount && calculateTotal() <= 0)} className="w-full bg-emerald-600 hover:bg-emerald-700" data-testid="record-payment-btn">
              <Check className="w-4 h-4 mr-2" />{submitting ? "Recording..." : `Record Payment ₹${calculateTotal().toLocaleString()}`}
            </Button>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
