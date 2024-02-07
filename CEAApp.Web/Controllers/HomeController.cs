using CEAApp.Web.DIServices;
using CEAApp.Web.Models;
using Microsoft.AspNetCore.Mvc;
using System.Diagnostics;

namespace CEAApp.Web.Controllers
{
    public class HomeController : Controller
    {
        #region Fields
        private readonly ILogger<HomeController> _logger;
        private readonly IConfiguration _config;
        private readonly IConverterService _converter;
        #endregion

        public HomeController(ILogger<HomeController> logger, IConfiguration configuration, IConverterService converter)
        {
            _logger = logger;
            _config = configuration;
            _converter = converter;
        }
           
        public IActionResult Index()
        {
            // Redirect users to Project Inquiry view
            return RedirectToAction(nameof(Index), "Project", new { area = "UserFunctions" });
        }

        public IActionResult Privacy()
        {
            return View();
        }

        [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
        public IActionResult Error()
        {
            return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
        }
    }
}