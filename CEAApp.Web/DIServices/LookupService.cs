using CEAApp.Web.Repositories;
using Microsoft.AspNetCore.Mvc.Rendering;

namespace CEAApp.Web.DIServices
{
    public class LookupService : ILookupService
    {
        #region Fields
        private readonly IProjectRepository _repository;
        #endregion

        #region Constructors
        public LookupService(IProjectRepository repository) 
        { 
            _repository = repository;   
        }
        #endregion

        #region Implementation
        public int FiscalYear { get; set; }
        public List<int> ListFiscalYear()
        {
            List<int> list = new List<int>(); 
            if (_repository.LookupData.FiscalYearList != null)
            {
                foreach (var item in _repository.LookupData.FiscalYearList)
                {
                    list.Add(Convert.ToInt32(item.UDCValue));
                }
            }
            return list;
        }

        public string ExpenditureType { get; set; }
        public List<string> ListExpenditureType()
        {
            return new List<string>() { "CEA", "MRE", "INC" };
        }
        #endregion
    }
}
