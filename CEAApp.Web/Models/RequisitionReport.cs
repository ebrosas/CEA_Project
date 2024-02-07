using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CEAApp.Web.Models
{
    public class RequisitionReport
    {

        #region Properties

        [Display(Name = "No.")]
        public string? ProjectNo { get; set; }

        [Display(Name = "Cost Center")]
        public string? CostCenter { get; set; }

        [Display(Name = "Fiscal Year")]
        public Int16? FiscalYear { get; set; }

        [Display(Name = "Requisition No.")]
        public string? RequisitionNo { get; set; }

        [Display(Name = "Requisition Date")]
        public string? RequisitionDate { get; set; }

        [Display(Name = "Description")]
        public string? RequisitionDescription { get; set; }

        [Display(Name = "Requisition Status")]
        public string? RequisitionStatus { get; set; }

        [Display(Name = "Requisition Amount")]
        public Decimal? RequisitionAmount { get; set; }

        [Display(Name = "Expenditure Type")]
        public string? ExpenditureType { get; set; }

        #endregion
    }
}
