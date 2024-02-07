using System.ComponentModel.DataAnnotations;

namespace CEAApp.Web.Models
{
    public class FiscalYears
    {
        [Key]
        [Display(Name = "FiscalYear")]
        public string? FiscalYear { get; set; }

    }
}
