using System.ServiceModel;

namespace CEAApp.Web.Models
{
    public class GlobalSettings
    {
        #region Constants
        public const int ACTIVITY_STATUS_CREATED = 106;
        public const int ACTIVITY_STATUS_IN_PROGRESS = 107;
        public const int ACTIVITY_STATUS_SKIPPED = 108;
        public const int ACTIVITY_STATUS_COMPLETED = 109;
        public const int DB_STATUS_OK = 0;
        public const int DB_STATUS_ERROR = -1;
        public const int DB_STATUS_ERROR_DUPLICATE = -2;
        public const int DB_STATUS_WF_CANCELLED = -3;
        public const int DB_STATUS_ERROR_NO_COST_CENTER_APPROVAL = -10;
        public const int DB_STATUS_ERROR_CHART_ACCOUNT_NOT_FOUND = -50;
        public const int DB_STATUS_ERROR_NOT_CURRENT_DIST_MEMBER = -100;
        public const int DB_WORKFLOW_ERROR = -69;
        public const int REQUEST_TYPE_CEA = 22;

        #region Workflow Statuses
        public const string STATUS_CANCELLED_BY_USER = "101";
        public const string STATUS_CODE_DRAFT = "01";
        public const string STATUS_CODE_REQUEST_SENT = "02";
        public const string STATUS_CODE_APPROVED = "120";
        public const string STATUS_CODE_ASSIGNEDTO_NEXT_APPROVER = "121";
        public const string STATUS_CODE_CLOSE_BY_APPROVER = "123";
        public const string STATUS_CODE_REASSIGNED_TO_OTHER_APPROVER = "122";
        public const string STATUS_CODE_REJECTED = "110";
        public const string STATUS_CODE_WAITING_FOR_APPROVAL = "05";
        public const string STATUS_CODE_REJECTED_BY_VALIDATOR = "112";
        public const string STATUS_CODE_REVIEWED_BY_VALIDATOR = "130";
        public const string STATUS_CODE_REASSIGNED_OTHER_VALIDATOR = "132";
        public const string STATUS_CODE_FOR_VALIDATION = "16";
        public const string STATUS_CODE_FOR_EVALUATION = "510";
        public const string STATUS_CODE_RESUBMITTED_FOR_APPROVAL = "511";
        public const string STATUS_HANDLING_CODE_APPROVED = "Approved";
        public const string STATUS_HANDLING_CODE_CANCELLED = "Cancelled";
        public const string STATUS_HANDLING_CODE_CLOSED = "Closed";
        public const string STATUS_HANDLING_CODE_OPEN = "Open";
        public const string STATUS_HANDLING_CODE_REJECTED = "Rejected";
        public const string STATUS_HANDLING_CODE_VALIDATED = "Validated";
        public const string SUBMITTED_FOR_APPROVAL = "SubmittedForApproval";
        #endregion

        #endregion

        #region Enumerations
        public enum CEAFormCodes
        {
            PROJECTINQ,         // Project Inquiry
            REQUESTINQ,         // Requisition Inquiry
            PROJDETAIL,         // Project Details
            DETLEXPRPT,         // DetailedExpenses Report
            EXPENSERPT,         // Expenses Report
            REQUESTRPT,         // Requisition Report
            PROJCTUPLD,         // Project Upload
            REQUESTADM,         // Request Administration
            EQUIPTASGN,         // Equipment Number Assignment
            CEAENTRY,           // CEA Data Entry page
            REASSIGN            // Reassignment Page
        }

        public enum FormTitles
        {
            ProjectInquiry,
            RequisitionInquiry,
            CEARequisition
        }

        public enum ActionTypeOption
        {
            ReadOnly,
            EditMode,
            CreateNew,
            Approval,
            FetchEmployee,
            Draft,
            ShowReport,
            ForValidation,
            UploadToJDE
        }

        public enum ButtonType
        {
            View,
            Edit,
            Delete
        }

        public enum CEAStatusCode
        {
            Draft = 1,
            Submitted = 2,
            Approved = 3,
            Completed = 4,            
            SubmittedForApproval = 5,
            Rejected = 8,
            AwaitingApproval = 9,
            Cancelled = 10,
            Closed = 11,
            ChairmanApproved = 14,
            UploadedToOneWorld = 15,
            DraftAndSubmitted = 16,
            AwaitingChairmanApproval = 17,
            RequisitionAdministration = 18
        }
        #endregion

        #region Workflow Enums
        public enum RequestType
        {
            ExpenseRequest = 1,
            TravelRequest,
            CashAdvanceRequest
        }

        public enum ActivityType
        {
            NoActivity = 0,
            Action,
            Condition,
            Function,
            Process,
            SendMail
        }

        public enum RequestTypeStatusCode
        {
            AssignedToNextServiceProvider = 14,
            AssignedToNextApprover = 121,
            ReassignedToOtherServiceProvider = 15,
            ReassignedToOtherApprover = 122,
            ReassignedToOtherValidator = 132,
            AssignedtoBuyer = 133,
            RequestSent = 2,
            Draft = 1,
            WaitingForApproval = 5,
            AssignedToServiceProvider = 10,
            WaitingForUserResponse = 11,
            WaitingForVendorResponse = 12,
            WorkInProgress = 13,
            PRPartiallyClosed = 134,
            OQPartiallyClosed = 136,
            ApprovedByApprover = 120,
            ApprovedByTheCEO = 124,
            NoActionRequired = 97,
            ClosedByServiceProvider = 98,
            ClosedByUser = 99,
            ClosedByApprover = 123,
            ClosedByValidator = 131,
            PRClosed = 135,
            OQClosed = 137,
            PAFPosted = 138,
            PRCancelledRejected = 139,
            OQCancelledRejected = 140,
            CancelledByServiceProvider = 100,
            UploadedToJDE = 160,
            CancelledByUser = 101,
            RejectedByApprover = 110,
            RejectedByServiceProvider = 111,
            RejectedByValidator = 112,
            ForValidation = 16,
            ValidatedByValidator = 130,
            TicketNotYetProcess = 150,
            TicketInProgress = 151,
            TicketBooked = 152,
            TicketReceivedByUser = 153,
            SentBackToUser = 6,
            OpenForBidding = 200,
            ClosedForBidding = 201,
            InitializedBid = 202,
            BidSubmitted = 203,
            DeclinedToBid = 204,
            BidAwarded = 205,
            OrderCancelled = 206,
            SuppliersSelected = 207
        }

        public enum ServiceRole
        {
            Approver = 64,
            ServiceProvider = 65,
            Validator = 151
        }

        public enum WorkflowStateType
        {
            RequestSubmittedState,
            RequestResumedState,
            RequestCancelledState,
            UnknowState
        }

        public enum ActivityActionType
        {
            ActionNotDefined,
            ActionApproved,
            ActionRejected,
            ActionValidated,
            ActionAssigned,
            ActionReassigned,
            ActionSendBackToUser,
            ActionClosed
        }

        public enum UserActionType
        {
            NoAction = 0,
            CancelRequest = 1,
            ApproveRequest = 2,
            RejectRequest = 3,
            ValidateRequest = 4,
            ReassignRequest = 5
        }

        public enum WFActionType
        {
            SubmitRequest = 1,
            ValidateRequest,
            ApproveRequest,
            RejectRequest
        }

        public enum WorkflowStatus
        {
            ACTIVITY_STATUS_UNKNOWN = 0,
            ACTIVITY_STATUS_CREATED = 106,
            ACTIVITY_STATUS_IN_PROGRESS = 107,
            ACTIVITY_STATUS_SKIPPED = 108,
            ACTIVITY_STATUS_COMPLETED = 109
        }

        public enum DBResultStatus
        {
            DB_STATUS_ERROR = -1,
            DB_STATUS_ERROR_DUPLICATE = -2,
            DB_STATUS_ERROR_NOT_CURRENT_DIST_MEMBER = -100,
            DB_STATUS_ERROR_NO_COST_CENTER_APPROVAL = -10,
            DB_STATUS_OK = 0
        }
        #endregion

        #region Public Methods
        public static BasicHttpBinding GetCustomBinding()
        {
            try
            {
                //BasicHttpBinding bTHttpBinding = new BasicHttpBinding("BasicHttpEndpoint");

                #region Code commented for future use
                BasicHttpBinding bTHttpBinding = new BasicHttpBinding(BasicHttpSecurityMode.TransportCredentialOnly);
                bTHttpBinding.Security.Transport.ClientCredentialType = HttpClientCredentialType.Ntlm;
                //bTHttpBinding.Security.Transport.ClientCredentialType = HttpClientCredentialType.None;
                bTHttpBinding.MaxBufferSize = int.MaxValue;
                bTHttpBinding.MaxBufferPoolSize = int.MaxValue;
                bTHttpBinding.MaxReceivedMessageSize = int.MaxValue;
                bTHttpBinding.CloseTimeout = TimeSpan.FromMinutes(30);
                bTHttpBinding.OpenTimeout = TimeSpan.FromMinutes(30);
                bTHttpBinding.ReceiveTimeout = TimeSpan.FromMinutes(30);
                bTHttpBinding.SendTimeout = TimeSpan.FromMinutes(30);
                bTHttpBinding.ReaderQuotas.MaxDepth = int.MaxValue;
                bTHttpBinding.ReaderQuotas.MaxStringContentLength = int.MaxValue;
                bTHttpBinding.ReaderQuotas.MaxArrayLength = int.MaxValue;
                bTHttpBinding.ReaderQuotas.MaxBytesPerRead = int.MaxValue;
                bTHttpBinding.ReaderQuotas.MaxNameTableCharCount = int.MaxValue;
                #endregion

                return bTHttpBinding;
            }
            catch (Exception ex)
            {
                return new BasicHttpBinding();
            }
        }
        #endregion
    }
}
