using CEAApp.Web.Models;
using Microsoft.AspNetCore.Mvc.Rendering;

namespace CEAApp.Web.ViewModels
{
     class ExpensesReportVM : ViewModelBase
    {
        public ExpensesReport ExpensesReport { get; set; }

        public List<ExpensesReport> expensesReportList { get; set; }

        public List<SelectListItem> costCenterList { get; set; }

        public List<SelectListItem> ExpenseTypeList { get; set; }

        public List<SelectListItem> FiscalYearList { get; set; }

    }
}
