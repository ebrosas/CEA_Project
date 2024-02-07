using Microsoft.AspNetCore.Mvc.Rendering;

namespace CEAApp.Web.Repositories
{
    public interface ICostCenterRepository
    {
        Task<SelectList> GetCostCenterAsync();
    }
}
