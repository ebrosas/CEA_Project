using System.ComponentModel.DataAnnotations;

namespace CEAApp.Web.Models
{
    public class CostCenters
    {

        [Display(Name = "Cost Centers")]
        public string? CostCenter { get; set; }

        [Display(Name = "CostCenterName")]
        public string? CostCenterName { get; set; }

    }
}
