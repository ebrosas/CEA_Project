using Microsoft.AspNetCore.Mvc.Rendering;
using System.ComponentModel.DataAnnotations;

namespace CEAApp.Web.Models
{
    class CEARequisitionVM : ViewModelBase
    {
        #region Properties

        public List<SelectListItem>? CostCenterList { get; set; } = null;
        public List<SelectListItem>? FiscalYearList { get; set; } = null;
        public List<SelectListItem>? ItemTypeList { get; set; } = null;
        public List<SelectListItem>? PlantLocationList { get; set; } = null;
        public List<SelectListItem>? ExpenditureTypeList { get; set; } = null;
        public List<SelectListItem>? ExpenseYearList { get; set; } = null;
        public List<SelectListItem>? ExpenseQuarterList { get; set; } = null;
        public CEARequest? CEARequestDetail { get; set; }
        public List<EmployeeDetail>? CEAAdminList { get; set; } = null;
        #endregion
    }
}
