using Microsoft.AspNetCore.Mvc.Rendering;
using CEAApp.Web.Models;

namespace CEAApp.Web.Repositories
{
    public interface IExpensesReportRepository
    {
        Task<List<ExpensesReport>> ExpensesReportList(string costCenter, string expenditureType, int? fromFiscalYear, int? toFiscalYear, string projectStatusId, int requisitionStatusId, int? startRowIndex, int? maximumRows);

        Task<List<ExpensesReport>> LoadExpenseReportAsync(string costCenter, string expenditureType, int? fromFiscalYear, int? toFiscalYear, string projectStatusId, int requisitionStatusId, int? startRowIndex, int? maximumRows);

        //Task<SelectList> GetCostCenterAsync(int userId);

        //Task<SelectList> GetExpenseTypeAsync();

        //Task<SelectList> GetFiscalYearAsync();

        Task<List<DetailedExpensesReport>> LoadDetailedExpenseReportAsync(string costCenter, string expenditureType, int? fromFiscalYear, int? toFiscalYear, string projectStatusId, int requisitionStatusId, int? startRowIndex, int? maximumRows);

        Task<List<RequisitionReport>> LoadRequisitionReportAsync(string costCenter, string expenditureType, int? fromFiscalYear, int? toFiscalYear, string projectStatusId, int requisitionStatusId, int? startRowIndex, int? maximumRows);

        Task<List<RequisitionPrint>> LoadRequisitionPrintAsync(int requisitionId);

        Task<List<RequisitionApprover>> LoadRequisitionApproverPrintAsync(int requisitionId);

        Task<List<RequisitionExpense>> LoadRequisitionExpensesPrintAsync(int requisitionId);

        Task<ReferenceData> GetLookupTable(string objectCode = "");

    }
}
