using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CEAApp.Web.Models
{
    public class DetailedExpensesReport
    {
        #region Properties

        
        [Display(Name = "No.")]
        public string? ProjectNo { get; set; }

        [Display(Name = "Cost Center")]
        public string? CostCenter { get; set; }

        [Display(Name = "Fiscal Year")]
        public Int16? FiscalYear { get; set; }

        [Display(Name = "Description")]
        public string? ProjectDescription { get; set; }

        [Display(Name = "Expenditure Type")]
        public string? ExpenditureType { get; set; }

        [Display(Name = "Budget")]
        public string? ProjectBudget { get; set; }

        [Display(Name = "Status")]
        public string? ProjectStatus { get; set; }

        [Display(Name = "No")]
        public string? RequisitionNo { get; set; }

        [Display(Name = "Description")]
        public string? RequisitionDescription { get; set; }

        [Display(Name = "Budget")]
        public string? RequisitionBudget { get; set; }

        [Display(Name = "Status")]
        public string? RequisitionStatus { get; set; }

        [Display(Name = "Order No.")]
        public string? PurchaseOrderNo { get; set; }

        [Display(Name = "OrderLine No")]
        public string? PurchaseOrderLineNo { get; set; }

        [Display(Name = "No.")]
        public string? VoucherNo { get; set; }

        [Display(Name = "Type")]
        public string? VoucherType { get; set; }

        [Display(Name = "Paid Amount")]
        public string? VoucherPaidAmount { get; set; }

        [Display(Name = "Item No.")]
        public string? VoucherItemNo { get; set; }

        [Display(Name = "Currency")]
        public string? VoucherCurrency { get; set; }

        [Display(Name = "No.")]
        public Double PaymentNo { get; set; }

        [Display(Name = "Date")]
        public string? PaymentDate { get; set; }

        [Display(Name = "Document Type")]
        public string? PaymentDocumentType { get; set; }

        [Display(Name = "ActualPaid Amount")]
        public string? PaymentActualPaidAmount { get; set; }

        #endregion
    }
}
