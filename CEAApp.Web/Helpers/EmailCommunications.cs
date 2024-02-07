using CEAApp.Web.Models;
using CEAApp.Web.ViewModels;
using iText.Html2pdf.Html;
using iText.Layout;
using Microsoft.EntityFrameworkCore.Metadata.Internal;
using Microsoft.Extensions.FileProviders;
using NuGet.Protocol.Core.Types;
using Org.BouncyCastle.Asn1.X509;
using Org.BouncyCastle.Cms;
using System.Net.Mail;
using System.Text;
using System.Xml;
using static Org.BouncyCastle.Math.EC.ECCurve;

namespace CEAApp.Web.Helpers
{
    public class EmailCommunications
    {
        private readonly IConfiguration _config;
        private readonly IFileProvider _fileProvider;

        public EmailCommunications(IConfiguration config, IFileProvider fileProvider)
        {
            _config = config;
            _fileProvider = fileProvider;
        }

        public void SendEmailToApprovers(string emailSubject, string emailBody, ApproversDetails approver)
        {
            try
            {
                if (approver != null)
                {
                    MailMessage mail = new MailMessage();
                    bool isTestMode;

                    var appSettingOptions = new AppSettingOptions();
                    _config.GetSection(AppSettingOptions.AppSettings).Bind(appSettingOptions);

                    if (appSettingOptions.TestMode == "1" && !string.IsNullOrWhiteSpace(appSettingOptions.TestUserID))
                        isTestMode = true;
                    else
                        isTestMode = false;

                    int indexLoc = 0;
                    string newEmailAddress = string.Empty;

                    if (isTestMode)
                    {
                        #region Append underscore to the email address if in test mode
                        if (!string.IsNullOrEmpty(approver.ApproverEmail))
                        {
                            indexLoc = approver.ApproverEmail.IndexOf("@");
                            if (indexLoc > 0)
                            {
                                newEmailAddress = approver.ApproverEmail.Replace(approver.ApproverEmail.Substring(indexLoc + 1),
                                    string.Concat("_", approver.ApproverEmail.Substring(indexLoc + 1)));

                                // Add email address
                                mail.To.Add(new MailAddress(newEmailAddress, approver.ApproverName));
                            }
                        }
                        #endregion
                    }
                    else
                    {
                        //mail.To.Add(new MailAddress(approver.ApproverEmail, approver.EmpName));
                    }

                    List<MailAddress> bccList = null;
                    string[] recipientArray = null;

                    #region Add Bcc mail receipent
                    recipientArray = appSettingOptions.WorkflowBccRecipients.Split(';');
                    if (recipientArray != null && recipientArray.Count() > 0)
                    {
                        // Initialize the collection
                        bccList = new List<MailAddress>();

                        foreach (string recipient in recipientArray)
                        {
                            if (recipient.Length > 0)
                                bccList.Add(new MailAddress(recipient, recipient));
                        }
                    }

                    if (bccList != null)
                    {
                        foreach (MailAddress bcc in bccList)
                            mail.Bcc.Add(bcc);
                    }
                    #endregion

                    #region Add recipients
                    mail.Subject = emailSubject;
                    mail.Body = emailBody;
                    mail.IsBodyHtml = true;
                    mail.From = new MailAddress(appSettingOptions.AdminEmail, appSettingOptions.AdminName);
                    #endregion

                    // Create an smtp client and send the mail message
                    SmtpClient smtpClient = new SmtpClient(appSettingOptions.GARMCOSMTP);
                    smtpClient.UseDefaultCredentials = true;

                    // Send the mail message
                    smtpClient.Send(mail);
                }
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }

        public string UploadToOneWorldMailBody(ApproversDetails Approvers)
        {
            var appSettingOptions = new AppSettingOptions();
            _config.GetSection(AppSettingOptions.AppSettings).Bind(appSettingOptions);

            //#region Set Message Body - ( XML )
            //string folderPath = appSettingOptions.TemplatePath;
            //string? filePath = ((PhysicalFileProvider) _fileProvider).Root + folderPath + "UploadedToOneWorldNotification.xml";
            //string? siteUrl = appSettingOptions.SiteUrl;

            // Build the link
            //string siteLink = String.Format("<a href='{0}'>{1}</a>",siteUrl.ToString() +
            //"UserFunctions/Project/CEARequisition?requisitionNo=" + Approvers.RequisitionNo + "&actionType=0&callerForm=UploadToOneWorld",
            //Approvers.RequisitionNo);


            //StringBuilder body = new StringBuilder();
            //body.Append("<div style='font-family: Tahoma; font-size: 10pt'>");
            //body.Append(String.Format(RetrieveXmlMessage(filePath), Approvers.ApproverName, siteLink).Replace("\r\n", "<br />"));
            //body.Append("</div>");
            //#endregion

            #region Set Message Body - (HTML style)
            string body = String.Empty;
            //string url = string.Format(@"{0}UserFunctions/Project/CEARequisition?requisitionNo={1}&actionType=3", siteUrl.ToString(), Approvers.RequisitionNo);
            string adminName = appSettingOptions.AdminName;

            // Set the path of the xml message and the url
            string appPath = Environment.CurrentDirectory;
            if (Environment.CurrentDirectory.IndexOf("\\bin") > -1)
                appPath = Environment.CurrentDirectory.Substring(0, Environment.CurrentDirectory.IndexOf("\\bin"));

            using (StreamReader reader = new StreamReader(appPath + @"\wwwroot\MailTemplates\UploadedToOneWorldNotification.html"))
            {
                body = reader.ReadToEnd();
            }

            // Build the message body
            if (!string.IsNullOrEmpty(body))
            {
                body = body.Replace("@1", Approvers.ApproverName!.ToUpper());
                body = body.Replace("@2", Approvers.RequisitionNo!.ToString());
            }
            #endregion

            return body.ToString();
        }

        private static string RetrieveXmlMessage(string xmlFile)
        {
            string message = String.Empty;
            XmlTextReader reader = null;

            try
            {
                // Read the file
                reader = new XmlTextReader(xmlFile);
                while (reader.Read())
                {
                    if (reader.NodeType == XmlNodeType.Text)
                        message = reader.Value;
                }
            }

            catch
            {
            }

            finally
            {
                if (reader != null)
                    reader.Close();
            }

            return message;
        }


        public string ReAssignRequisitionMailBody(ApproversDetails Approvers, List<string> selectedRequisitionList)
        {
            var appSettingOptions = new AppSettingOptions();
            _config.GetSection(AppSettingOptions.AppSettings).Bind(appSettingOptions);

            //string folderPath = appSettingOptions.TemplatePath;
            //string? filePath = ((PhysicalFileProvider)_fileProvider).Root + folderPath + "ReassignmentRequisitionNotification.xml";
            string? siteUrl = appSettingOptions.SiteUrl;

            #region Make the list of request
            List<string> requisitionNoList = new List<string>();
            requisitionNoList.Add("<ol>");
            foreach (var item in selectedRequisitionList)
            {
                var requisitionDetail = new RequisitionDetail();

                string[] reqDetails = item.Split(",");
                string RequisitionNo = reqDetails[0].Replace("[", string.Empty);
                int EmpNo = Convert.ToInt32(reqDetails[1].Replace("]", string.Empty));

                string siteLink = String.Format("<a href='{0}'>{1}</a>", siteUrl.ToString() +
                                  "UserFunctions/Project/CEARequisition?requisitionNo=" + RequisitionNo.ToString() + "&actionType=0&callerForm=Reassignment",
                                  " Click here to view the details of requisition No. - " + RequisitionNo.ToString());

                requisitionNoList.Add(string.Format("<li>{0}</li>", siteLink.ToString()));
            }
            requisitionNoList.Add("</ol>");

            string requistions = string.Join(Environment.NewLine, requisitionNoList.ToArray());

            #endregion

            #region Set Message Body
            string body = String.Empty;
            //string url = string.Format(@"{0}UserFunctions/Project/CEARequisition?requisitionNo={1}&actionType=3", siteUrl.ToString(), Approvers.RequisitionNo);
            string adminName = appSettingOptions.AdminName;

            // Set the path of the xml message and the url
            string appPath = Environment.CurrentDirectory;
            if (Environment.CurrentDirectory.IndexOf("\\bin") > -1)
                appPath = Environment.CurrentDirectory.Substring(0, Environment.CurrentDirectory.IndexOf("\\bin"));

            using (StreamReader reader = new StreamReader(appPath + @"\wwwroot\MailTemplates\NotifyReAssignment.html"))
            {
                body = reader.ReadToEnd();
            }

            // Build the message body
            if (!string.IsNullOrEmpty(body))
            {
                body = body.Replace("@1", Approvers.ApproverName!.ToUpper());
                body = body.Replace("@2", requistions.ToString());
            }
            #endregion

            return body.ToString();
        }
    }
}
