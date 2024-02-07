using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CEAApp.Web.Models
{
    public class FinancialDetail
    {
        #region Properties
        [Key]
        public int RequisitionID { get; set; }
        public int ExpenseID { get; set; }

        [Display(Name = "Amount")]
        [DisplayFormat(DataFormatString = "{0:0,000.000}", ApplyFormatInEditMode = true)]
        public decimal? Amount { get; set; }

        [Display(Name = "Year")]
        public int? FiscalYear { get; set; }
        public string Quarter { get; set; } = null!;
        public bool IsDummy { get; set; }
        #endregion
    }
}
