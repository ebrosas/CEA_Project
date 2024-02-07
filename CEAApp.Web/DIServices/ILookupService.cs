using Microsoft.AspNetCore.Mvc.Rendering;

namespace CEAApp.Web.DIServices
{
    public interface ILookupService
    {
        int FiscalYear { get; set; }
        List<int> ListFiscalYear();
        List<string> ListExpenditureType();
    }
}
