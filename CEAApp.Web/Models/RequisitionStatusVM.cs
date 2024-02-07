using System.ComponentModel.DataAnnotations;

namespace CEAApp.Web.Models
{
    class RequisitionStatusVM : ViewModelBase
    {
        #region Properties
        [Display(Name ="Prepared By")]
        public string? CreatedBy { get; set; }

        [Display(Name = "Submitted Date")]
        public DateTime? SubmittedDate { get; set; }

        public List<RequisitionStatus>? ApprovalList { get; set; }
        public List<WFApprovalStatus>? WFApprovalList { get; set; }
        #endregion
    }
}
