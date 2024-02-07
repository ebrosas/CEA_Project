using CEAApp.Web.Models;
using Microsoft.AspNetCore.Mvc.Rendering;

namespace CEAApp.Web.ViewModels
{
    class RequisitionReportVM : ViewModelBase
    {
        public RequisitionReport RequisitionReport { get; set; }

        public List<RequisitionReport> RequisitionReportList { get; set; }

        public List<SelectListItem> costCenterList { get; set; }

        public List<SelectListItem> ExpenseTypeList { get; set; }

        public List<SelectListItem> FiscalYearList { get; set; }


    }
}
