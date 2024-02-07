using System.ComponentModel.DataAnnotations;

namespace CEAApp.Web.Models
{
    class ExpenseVM : ViewModelBase
    {
        #region Properties
        [Display(Name = "Submitted Date")]
        public DateTime? SubmittedDate { get; set; }
        
        public List<ExpenseDetail>? ExpenseList { get; set; }
        #endregion
    }
}
