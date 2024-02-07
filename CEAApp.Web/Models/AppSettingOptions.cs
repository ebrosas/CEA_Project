namespace CEAApp.Web.Models
{
    public class AppSettingOptions
    {
        #region Fields
        public const string AppSettings = "AppSettings";
        #endregion

        #region Properties
        public string JavaScriptFileVersion { get; set; } = string.Empty;
        public string TestMode { get; set; } = string.Empty;
        public string TestUserID { get; set; } = string.Empty;
        public string EmailTestMode { get; set; } = string.Empty;
        public string LDAPPath { get; set; } = string.Empty;
        public string LDAPUsername { get; set; } = string.Empty;
        public string LDAPPassword { get; set; } = string.Empty;
        public string WFEngineURL { get; set; } = string.Empty;
        public string GARMCOSMTP { get; set; } = string.Empty;
        public string AdminEmail { get; set; } = string.Empty;
        public string AdminName { get; set; } = string.Empty;
        public string IsThrowEmailException { get; set; } = string.Empty;
        public string WorkflowBccRecipients { get; set; } = string.Empty;
        public string TemplatePath { get; set; } = string.Empty;
        public string SiteUrl { get; set; } = string.Empty;
        #endregion
    }
}
