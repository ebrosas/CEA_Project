using CEAApp.Web.Models;
using Microsoft.AspNetCore.Mvc.Rendering;

namespace CEAApp.Web.ViewModels
{
    class DetailedExpensesReportVM  : ViewModelBase
    {
        public DetailedExpensesReport DetailedExpensesReport { get; set; }

        public List<DetailedExpensesReport> detailedExpensesReportList { get; set; }

        public List<SelectListItem> costCenterList { get; set; }

        public List<SelectListItem> ExpenseTypeList { get; set; }

        public List<SelectListItem> FiscalYearList { get; set; }


    }
}
