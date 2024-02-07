using Microsoft.EntityFrameworkCore;
using CEAApp.Web.DIServices;
using CEAApp.Web.Models;
using CEAApp.Web.Repositories;
using Microsoft.Extensions.FileProviders;
using Microsoft.AspNetCore.Authentication.Negotiate;
using Microsoft.AspNetCore.Authentication.Cookies;
using static System.Net.Mime.MediaTypeNames;
using Microsoft.AspNetCore.Diagnostics;
using CEAApp.Web.Helpers;

var builder = WebApplication.CreateBuilder(args);

// Enable Window Authentication
builder.Services.AddAuthentication(NegotiateDefaults.AuthenticationScheme).AddNegotiate();

// Enable athorization
builder.Services.AddAuthorization(options =>
{
    options.FallbackPolicy = options.DefaultPolicy;
});

// Configure session state
builder.Services.AddDistributedMemoryCache();

builder.Services.AddSession(options =>
{
    //options.IdleTimeout = TimeSpan.FromSeconds(10);
    options.IdleTimeout = TimeSpan.FromDays(40);
    options.Cookie.HttpOnly = true;
    options.Cookie.IsEssential = true;
});

// Register DB Context into the DI container
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("CEAConnectionString") ?? throw new InvalidOperationException("Connection string 'CEAConnectionString' not found.")));

builder.Services.AddHttpContextAccessor();      // This service is used to get information about the current logged-on user

// Add services to the container.
builder.Services.AddControllersWithViews()
    .AddMvcOptions(options =>
    {
        options.MaxModelValidationErrors = 50;
        options.ModelBindingMessageProvider.SetValueMustNotBeNullAccessor(
            _ => "This field is required.");
    });

#region Register services into the DI container
builder.Services.AddScoped<IProjectRepository, ProjectRepository>();
builder.Services.AddScoped<IConverterService, ConverterService>();
builder.Services.AddScoped<ILookupService, LookupService>();
builder.Services.AddScoped<IExpensesReportRepository, ExpensesReportRepository>();
builder.Services.AddScoped<ICostCenterRepository, CostCenterRepository>();
builder.Services.AddScoped<IRequisitionRepository, RequisitionRepository>();

builder.Services.AddScoped<ExcelDataUpload>();
builder.Services.AddScoped<IExcelUploadRepository, ExcelUploadRepository>();
builder.Services.AddTransient<CEAApp.Web.Areas.UserFunctions.Controllers.SecurityController, CEAApp.Web.Areas.UserFunctions.Controllers.SecurityController>();
builder.Services.AddTransient<EmailCommunications>();
#endregion

builder.Services.AddDbContext<ApplicationDbContext>
    (options => options.UseSqlServer(builder.Configuration.GetConnectionString("CEAConnectionString")), ServiceLifetime.Transient);

IFileProvider physicalProvider = new PhysicalFileProvider(Directory.GetCurrentDirectory());

builder.Services.AddSingleton<IFileProvider>(physicalProvider); // This accessing wwwroot

builder.Services.AddSingleton<IFileProvider>(
           new PhysicalFileProvider(
               Path.Combine(Directory.GetCurrentDirectory(), "wwwroot")));


var app = builder.Build();


// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();    // Reports app runtime errors.
}
else
{
    // To configure a custom error handling page for the Production environment
    //app.UseExceptionHandler("/Home/Error");
    app.UseExceptionHandler(exceptionHandlerApp =>
    {
        exceptionHandlerApp.Run(async context =>
        {
            context.Response.StatusCode = StatusCodes.Status500InternalServerError;

            // using static System.Net.Mime.MediaTypeNames;
            context.Response.ContentType = Text.Plain;

            await context.Response.WriteAsync("An exception was thrown.");

            var exceptionHandlerPathFeature =
                context.Features.Get<IExceptionHandlerPathFeature>();

            if (exceptionHandlerPathFeature?.Error is FileNotFoundException)
            {
                await context.Response.WriteAsync(" The file was not found.");
            }

            if (exceptionHandlerPathFeature?.Path == "/")
            {
                await context.Response.WriteAsync(" Page: Home.");
            }
        });
    });


    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    //app.UseHsts();
}

// To enable default text-only handlers for common error status codes
//app.UseStatusCodePages(Text.Plain, "Status Code Page: {0}");

// Returns static files and short-circuits further request processing.
app.UseStaticFiles();

// Used to route requests.
app.UseRouting();

// Add Authentication Middleware to enable windows authentication (Notes: Code must be put before the call to use authorization)
// Attempts to authenticate the user before they're allowed access to secure resources.
app.UseAuthentication();

// Authorizes a user to access secure resources.
app.UseAuthorization();

// Configure session state
app.UseSession();

#region Initialize routes
// Define a route that reference the area
app.MapAreaControllerRoute(
    name: "AdminFunctionsArea",
    areaName: "AdminFunctions",
    pattern: "AdminFunctions/{controller=Home}/{action=Index}/{id?}");

app.MapAreaControllerRoute(
    name: "ReportFunctionsArea",
    areaName: "ReportFunctions",
    pattern: "ReportFunctions/{controller=Home}/{action=Index}/{id?}");

app.MapAreaControllerRoute(
    name: "UserFunctionsArea",
    areaName: "UserFunctions",
    pattern: "UserFunctions/{controller=Project}/{action=Index}/{id?}");

//app.MapControllerRoute(
//                name: "BufferedFileUpload",
//                pattern: "BufferedFileUpload/{title}/{id?}",
//                defaults: new { controller = "BufferedFileUpload", action = "Index" });

// Define route for Administrative web forms
app.MapControllerRoute(
    name: "admin",
    pattern: "admin/{*article}",
    defaults: new { controller = "Admin", action = "AuthenticateUser" }
    );

// Define default route
app.MapDefaultControllerRoute();    // Note: This singe-line of code replaces the below code
#endregion

app.Run();
