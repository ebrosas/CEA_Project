using CEAApp.Web.DIServices;
using CEAApp.Web.Models;
using CEAApp.Web.Repositories;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json;
using System.Text.Encodings.Web;

namespace CEAApp.Web.Areas.UserFunctions.Controllers
{
    [Area("UserFunctions")]
    public class SecurityController : Controller
    {
        #region Fields
        private readonly IProjectRepository _repository;
        private readonly IConverterService _converter;
        private readonly ApplicationDbContext _context;
        private readonly IConfiguration _config;
        private readonly IHttpContextAccessor _httpContextAccessor;

        #region Constants
        private const string CONST_SUCCESS = "SUCCESS";
        private const string CONST_FAILED = "FAILED";
        #endregion

        #endregion

        #region Constructors
        public SecurityController(ApplicationDbContext context, IProjectRepository repository, IConverterService converter, IConfiguration config, IHttpContextAccessor httpContextAccessor)
        {
            _context = context;
            _repository = repository;
            _converter = converter;
            _config = config;
            _httpContextAccessor = httpContextAccessor;
        }
        #endregion

        #region Web Methods                
        public IActionResult NoAccessPage()
        {
            return View();
        }

        public ActionResult GetUserCredential(string userName)
        {
            try
            {
                var appSettingOptions = new AppSettingOptions();
                _config.GetSection(AppSettingOptions.AppSettings).Bind(appSettingOptions);

                EmployeeInfo model;
                if (appSettingOptions.TestMode == "1" && !string.IsNullOrWhiteSpace(appSettingOptions.TestUserID))
                {
                    model = _repository.GetEmployeeByDomainName(appSettingOptions.TestUserID, appSettingOptions.LDAPPath, appSettingOptions.LDAPUsername, appSettingOptions.LDAPPassword);
                }
                else
                {
                    // Get employee infor from Active Directory
                    model = _repository.GetEmployeeByDomainName(userName, appSettingOptions.LDAPPath, appSettingOptions.LDAPUsername, appSettingOptions.LDAPPassword);
                }

            // Convert data to Json
            return Json(new { data = model });

            }
            catch (Exception ex)
            {
                return null;
            }
        }

        public EmployeeInfo? GetUserCredentialWithImpersonation(string userName, ref string currentImpersonator)
        {
            EmployeeInfo? model = null;

            try
            {
                var appSettingOptions = new AppSettingOptions();
                _config.GetSection(AppSettingOptions.AppSettings).Bind(appSettingOptions);
                
                if (appSettingOptions.TestMode == "1" && !string.IsNullOrWhiteSpace(appSettingOptions.TestUserID))
                {                    
                    if (string.IsNullOrEmpty(currentImpersonator) || (!string.IsNullOrEmpty(currentImpersonator) && appSettingOptions.TestUserID != currentImpersonator))
                    {
                        model = _repository.GetEmployeeByDomainName(appSettingOptions.TestUserID, appSettingOptions.LDAPPath, appSettingOptions.LDAPUsername, appSettingOptions.LDAPPassword);
                        if (model != null)
                        {
                            // Save the current impersonator
                            currentImpersonator = model.UserID!;
                        }

                        return model;
                    }
                }
                 
                // Get employee infor from Active Directory
                model = _repository.GetEmployeeByDomainName(userName, appSettingOptions.LDAPPath, appSettingOptions.LDAPUsername, appSettingOptions.LDAPPassword);

                return model;

            }
            catch (Exception ex)
            {
                return null;
            }
        }

        public ActionResult GetUserFormAccess(string formCode, string costCenter, int empNo)
        {
            try
            {
                var model = _repository.GetUserFormAccess(formCode, costCenter, empNo);

                // Convert data to Json
                return Json(new { data = model });
                
            }
            catch (Exception ex)
            {
                return null;
            }
        }

        public IActionResult Error(string? actionName, string? offendingURL, string? source, string? message, string? innerMessage, string? stackTrace, string? callerForm)
        {
            ErrorViewModel model = new ErrorViewModel()
            {
                ActionName = actionName,
                OffendingURL = offendingURL,
                Source = source,
                Message = message,
                InnerMessage = innerMessage,
                StackTrace = stackTrace,
                CallerForm = callerForm
            };

            return View(model);
        }
        #endregion
    }
}
