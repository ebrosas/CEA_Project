using Microsoft.AspNetCore.Mvc.Rendering;
using System.ComponentModel.DataAnnotations;

namespace CEAApp.Web.Models
{
    class EmployeeVM : ViewModelBase
    {
        #region Properties
        public int? SelectedEmpNo { get; set; } = null!;
        
        [Display(Name = "Employee No.")]
        public int? FilterEmpNo { get; set; } = null;

        [Display(Name = "Employee Name")]
        public string? FilterEmpName { get; set; } = null;

        [Display(Name = "Cost Center")]
        public string? FilterCostCenter { get; set; } = null;

        public List<EmployeeDetail>? EmployeeList { get; set; } = null;
        public List<SelectListItem>? CostCenterArray { get; set; } = null;
        #endregion
    }
}
