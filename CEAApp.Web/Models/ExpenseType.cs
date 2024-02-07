using System.ComponentModel.DataAnnotations;

namespace CEAApp.Web.Models
{
    public class ExpenseType
    {
        [Key]
        [Display(Name = "udccode")]
        public string? udccode { get; set; }

        [Display(Name = "udcdesc")]
        public string? udcdesc1 { get; set; }
    }
}
