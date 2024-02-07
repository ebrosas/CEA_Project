using System.ComponentModel.DataAnnotations;

namespace CEAApp.Web.Models
{
    public class SearchCriteria
    {
        #region Properties
        [Display(Name = "Fiscal Year")]
        public int FiscalYear { get; set; }

        [Display(Name = "Expenditure Type")]
        public string? ExpenditureType { get; set; }

        [Display(Name = "Requisition Status")]
        public string? Status { get; set; }

        [Key]
        [Display(Name = "Project No.")]
        public string? ProjectNo { get; set; }

        [Display(Name = "Cost Center")]
        public string? CostCenter { get; set; }

        [Display(Name = "Requisition No.")]
        public string? RequisitionNo { get; set; }

        [Display(Name = "Keywords")]
        public string? Keywords { get; set; }

        [Display(Name ="Requisition Date")]
        public DateTime? StartDate { get; set; }

        [Display(Name = "Requisition Date")]
        public DateTime? EndDate { get; set; }

        public string? ApprovalType { get; set; }
        public int? EmpNo { get; set; }
        public int? SearchEmpNo { get; set; }
        public string? SearchEmpName { get; set; }

        [Display(Name = "Created By")]
        public byte CreatedBy { get; set; }
        #endregion
    }
}
