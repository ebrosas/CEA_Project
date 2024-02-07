using CEAApp.Web.Models;

namespace CEAApp.Web.Repositories
{
    public interface IExcelUploadRepository
    {
        Task<int> SaveFromExcel(IFormFile projectFileName, EmployeeInfo? empInfo);
    }
}
