using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CEAApp.Web.Models
{
    public partial class ExpensesReport
    {
        #region Properties

        [Display(Name = "Project No.")]
        public string? ProjectNo { get; set; }

        [Display(Name = "Cost Center")]
        public string? CostCenter { get; set; }

        [Display(Name = "Expenditure Type")]
        public string? ExpenditureType { get; set; }

        [Display(Name = "Fiscal Year")]
        public int? FiscalYear { get; set; }

        [Display(Name = "Project Status")]
        public string? ProjectStatus { get; set; }

        [Display(Name = "Requisition No")]
        public string? RequisitionNo { get; set; }

        [Display(Name = "Requisition Date")]
        public DateTime? RequisitionDate { get; set; }

        [Display(Name = "Budget")]
        public decimal? Budget { get; set; }

        [Display(Name = "Requisition Description")]
        public string? RequisitionDescription { get; set; }

        [Display(Name = "Requisition Status")]
        public string? RequisitionStatus { get; set; }

        [Display(Name = "Open Amount")]
        public decimal? OpenAmount { get; set; }

        [Display(Name = "Gl Amount")]
        public decimal? GlAmount { get; set; }

        [Display(Name = "Balance")]
        public decimal? Balance { get; set; }

        #endregion
    }
}
