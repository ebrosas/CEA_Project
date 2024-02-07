using Microsoft.AspNetCore.Mvc.Rendering;
using CEAApp.Web.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Data.SqlClient;

namespace CEAApp.Web.Repositories
{
    public class CostCenterRepository : ICostCenterRepository
    {
        private readonly ApplicationDbContext context;

        public CostCenterRepository(ApplicationDbContext context)
        {
            this.context = context;
        }

        public async Task<SelectList> GetCostCenterAsync()
        {
            try
            {
                SelectList costCenterList = null;

                var costCenters = await context
                    .CostCenter
                    .FromSqlRaw("exec Projectuser.spGetAllCostCenters")
                    .AsNoTracking()
                    .ToListAsync();

                if (costCenters != null)
                    costCenterList = new SelectList(costCenters, "CostCenter", "CostCenter Name");

                return costCenterList;
            }
            catch (SqlException sqlErr)
            {
                throw new Exception(sqlErr.Message.ToString());
            }
            catch (Exception ex)
            {
                return null;
            }
        }
    }
}
