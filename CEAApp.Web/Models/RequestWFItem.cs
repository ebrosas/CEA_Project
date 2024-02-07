using static CEAApp.Web.Models.GlobalSettings;

namespace CEAApp.Web.Models
{
    [Serializable]
    public class RequestWFItemNew
    {
        #region Properties
        private Guid _workflowID;
        public Guid WorkflowID
        {
            get
            {
                return this._workflowID;
            }

            set
            {
                this._workflowID = value;
            }
        }

        private string _instanceID = String.Empty;
        public string InstanceID
        {
            get
            {
                return this.WorkflowID.ToString();
            }

            set
            {
                this._instanceID = value;
                this.WorkflowID = new Guid(value);
            }
        }

        private RequestType _requestType = RequestType.ExpenseRequest;
        public RequestType RequestType
        {
            get
            {
                return this._requestType;
            }

            set
            {
                this._requestType = value;
                this.RequestTypeInt = (int)value;
            }
        }

        private int _requestTypeInt = (int)RequestType.ExpenseRequest;
        public int RequestTypeInt
        {
            get
            {
                return this._requestTypeInt;
            }

            set
            {
                this._requestTypeInt = value;
            }
        }

        private int _requestTypeNo = 0;
        public int RequestTypeNo
        {
            get
            {
                return this._requestTypeNo;
            }

            set
            {
                this._requestTypeNo = value;
            }
        }

        private ActivityType _activityType = ActivityType.SendMail;
        public ActivityType ActivityType
        {
            get
            {
                return this._activityType;
            }

            set
            {
                this._activityType = value;
            }
        }

        private int? _actID = 0;
        public int? ActivityID
        {
            get
            {
                return this._actID;
            }

            set
            {
                this._actID = value;
            }
        }

        private int _activityStatus = ACTIVITY_STATUS_IN_PROGRESS;
        public int ActivityStatus
        {
            get
            {
                return this._activityStatus;
            }

            set
            {
                this._activityStatus = value;
            }
        }

        private string _state = String.Empty;
        public string CurrentState
        {
            get
            {
                return this._state;
            }

            set
            {
                this._state = value;
            }
        }

        private string _connString = String.Empty;
        public string ConnectionString
        {
            get
            {
                return this._connString;
            }

            set
            {
                this._connString = value;
            }
        }

        private string _fromEmail = String.Empty;
        public string FromEmail
        {
            get
            {
                return this._fromEmail;
            }

            set
            {
                this._fromEmail = value;
            }
        }

        private string _fromName = String.Empty;
        public string FromName
        {
            get
            {
                return this._fromName;
            }

            set
            {
                this._fromName = value;
            }
        }

        private int _modifiedBy;
        public int ModifiedBy
        {
            get
            {
                return this._modifiedBy;
            }

            set
            {
                this._modifiedBy = value;
            }
        }

        private string _modifiedName = String.Empty;
        public string ModifiedName
        {
            get
            {
                return this._modifiedName;
            }

            set
            {
                this._modifiedName = value;
            }
        }

        private int _requestStatus = 0;
        public int RequestStatus
        {
            get
            {
                return this._requestStatus;
            }

            set
            {
                this._requestStatus = value;
            }
        }

        private RequestTypeStatusCode _requestStatusCode =
            RequestTypeStatusCode.RequestSent;
        public RequestTypeStatusCode RequestStatusCode
        {
            get
            {
                return this._requestStatusCode;
            }

            set
            {
                this._requestStatusCode = value;
            }
        }

        private int _retError = DB_STATUS_OK;
        public int ReturnError
        {
            get
            {
                return this._retError;
            }

            set
            {
                this._retError = value;
            }
        }

        #region For Approver, Validator and Service Providers
        private ServiceRole _serviceRole = ServiceRole.Approver;
        public ServiceRole ServiceRole
        {
            get
            {
                return this._serviceRole;
            }

            set
            {
                this._serviceRole = value;
            }
        }

        private bool _requestApproved;
        public bool RequestApproved
        {
            get
            {
                return this._requestApproved;
            }

            set
            {
                this._requestApproved = value;
            }
        }

        private string _requestApprovedRemarks = String.Empty;
        public string RequestApprovedRemarks
        {
            get
            {
                return this._requestApprovedRemarks;
            }

            set
            {
                this._requestApprovedRemarks = value;
            }
        }

        private int _requestCurrentDistMemEmpNo = 0;
        public int RequestCurrentDistMemEmpNo
        {
            get
            {
                return _requestCurrentDistMemEmpNo;
            }

            set
            {
                this._requestCurrentDistMemEmpNo = value;
            }
        }

        private int _requestNewCurrentDistMemEmpNo = 0;
        public int RequestNewCurrentDistMemEmpNo
        {
            get
            {
                return _requestNewCurrentDistMemEmpNo;
            }

            set
            {
                this._requestNewCurrentDistMemEmpNo = value;
            }
        }

        private string _requestNewCurrentDistMemEmpName = String.Empty;
        public string RequestNewCurrentDistMemEmpName
        {
            get
            {
                return this._requestNewCurrentDistMemEmpName;
            }

            set
            {
                this._requestNewCurrentDistMemEmpName = value;
            }
        }

        private string _requestNewCurrentDistMemEmpEmail = String.Empty;
        public string RequestNewCurrentDistMemEmpEmail
        {
            get
            {
                return this._requestNewCurrentDistMemEmpEmail;
            }

            set
            {
                this._requestNewCurrentDistMemEmpEmail = value;
            }
        }

        private int _requestRountineSeq = 0;
        public int RequestRoutineSeq
        {
            get
            {
                return _requestRountineSeq;
            }

            set
            {
                this._requestRountineSeq = value;
            }
        }

        private bool _requestCurrentDistMemOnHold = false;
        public bool RequestCurrentDistMemOnHold
        {
            get
            {
                return _requestCurrentDistMemOnHold;
            }

            set
            {
                this._requestCurrentDistMemOnHold = value;
            }
        }

        private string _requestSendBackSubject = String.Empty;
        public string RequestSendBackSubject
        {
            get
            {
                return this._requestSendBackSubject;
            }

            set
            {
                this._requestSendBackSubject = value;
            }
        }

        private string _requestSendBackMessage = String.Empty;
        public string RequestSendBackMessage
        {
            get
            {
                return this._requestSendBackMessage;
            }

            set
            {
                this._requestSendBackMessage = value;
            }
        }

        private string _requestReassignRemark = String.Empty;
        public string RequestReassignRemark
        {
            get
            {
                return this._requestReassignRemark;
            }

            set
            {
                this._requestReassignRemark = value;
            }
        }

        private string _wfActivityState = WorkflowStateType.UnknowState.ToString();
        public string CurrentWFState
        {
            get
            {
                return this._wfActivityState;
            }

            set
            {
                this._wfActivityState = value;
            }
        }

        private ActivityActionType _activityActionType = ActivityActionType.ActionNotDefined;
        public ActivityActionType ActivityActionType
        {
            get
            {
                return this._activityActionType;
            }

            set
            {
                this._activityActionType = value;
            }
        }

        private WorkflowStateType _activityStateType = WorkflowStateType.UnknowState;
        public WorkflowStateType ActivityStateType
        {
            get
            {
                return this._activityStateType;
            }

            set
            {
                this._activityStateType = value;
            }
        }


        private string _workflowDBConnectionString = String.Empty;
        public string WorkflowDBConnectionString
        {
            get
            {
                return this._workflowDBConnectionString;
            }

            set
            {
                this._workflowDBConnectionString = value;
            }
        }

        private UserActionType _userActionType = UserActionType.NoAction;
        public UserActionType UserActionType
        {
            get
            {
                return this._userActionType;
            }

            set
            {
                this._userActionType = value;
            }
        }

        private bool _requestRecreateWorkflow = false;
        public bool RequestRecreateWorkflow
        {
            get
            {
                return _requestRecreateWorkflow;
            }

            set
            {
                this._requestRecreateWorkflow = value;
            }
        }

        private string _mailServer = String.Empty;
        public string MailServer
        {
            get
            {
                return this._mailServer;
            }

            set
            {
                this._mailServer = value;
            }
        }

        private bool _emailTestMode;
        public bool EmailTestMode
        {
            get
            {
                return this._emailTestMode;
            }

            set
            {
                this._emailTestMode = value;
            }
        }

        private string _workflowBccRecipients = String.Empty;
        public string WorkflowBccRecipients
        {
            get
            {
                return this._workflowBccRecipients;
            }

            set
            {
                this._workflowBccRecipients = value;
            }
        }

        private string _actionEmailCcRecipients = String.Empty;
        public string ActionEmailCcRecipients
        {
            get
            {
                return this._actionEmailCcRecipients;
            }

            set
            {
                this._actionEmailCcRecipients = value;
            }
        }

        private string _notifyEmailCcRecipients = String.Empty;
        public string NotifyEmailCcRecipients
        {
            get
            {
                return this._notifyEmailCcRecipients;
            }

            set
            {
                this._notifyEmailCcRecipients = value;
            }
        }

        private bool _isThrowEmailException;
        public bool IsThrowEmailException
        {
            get
            {
                return this._isThrowEmailException;
            }

            set
            {
                this._isThrowEmailException = value;
            }
        }
        #endregion
        #endregion

        #region Constractors
        public RequestWFItemNew()
        {
        }

        public RequestWFItemNew(RequestType requestType, int requestTypeNo)
        {
            this.RequestType = requestType;
            this.RequestTypeNo = requestTypeNo;
        }

        public RequestWFItemNew(int requestType, int requestTypeNo)
        {
            this.RequestTypeInt = requestType;
            this.RequestTypeNo = requestTypeNo;
        }

        public RequestWFItemNew(string transDBConnectString, string wfDBConnectString, string wfInstanceID)
        {
            this.ConnectionString = transDBConnectString;
            this.WorkflowDBConnectionString = wfDBConnectString;
            this.WorkflowID = new Guid(wfInstanceID);
        }

        public RequestWFItemNew(int requestType, int requestTypeNo, string transDBConnectString, string wfDBConnectString)
        {
            this.RequestTypeInt = requestType;
            this.RequestTypeNo = requestTypeNo;
            this.ConnectionString = transDBConnectString;
            this.WorkflowDBConnectionString = wfDBConnectString;
        }

        public RequestWFItemNew(int requestType, int requestTypeNo, string transDBConnectString, string wfDBConnectString, string mailServer)
        {
            this.RequestTypeInt = requestType;
            this.RequestTypeNo = requestTypeNo;
            this.ConnectionString = transDBConnectString;
            this.WorkflowDBConnectionString = wfDBConnectString;
            this.MailServer = mailServer;
        }

        public RequestWFItemNew(int requestType, int requestTypeNo, string transDBConnectString, string wfDBConnectString, string mailServer, bool emailTestMode)
        {
            this.RequestTypeInt = requestType;
            this.RequestTypeNo = requestTypeNo;
            this.ConnectionString = transDBConnectString;
            this.WorkflowDBConnectionString = wfDBConnectString;
            this.MailServer = mailServer;
            this.EmailTestMode = emailTestMode;
        }

        public RequestWFItemNew(int requestType, int requestTypeNo, string transDBConnectString, string wfDBConnectString, UserActionType userActionType)
        {
            this.RequestTypeInt = requestType;
            this.RequestTypeNo = requestTypeNo;
            this.ConnectionString = transDBConnectString;
            this.WorkflowDBConnectionString = wfDBConnectString;
            this.UserActionType = userActionType;
        }

        public RequestWFItemNew(RequestType requestType, int requestTypeNo, ActivityType activityType) : this(requestType, requestTypeNo)
        {
            this.ActivityType = activityType;
        }

        public RequestWFItemNew(int requestType, int requestTypeNo,
            ActivityType activityType) : this(requestType, requestTypeNo)
        {
            this.ActivityType = activityType;
        }

        public RequestWFItemNew(RequestType requestType, int requestTypeNo,
            ActivityType activityType, string connString,
            int modifiedBy, string modifiedName)
        {
            this.RequestType = requestType;
            this.RequestTypeNo = requestTypeNo;
            this.ActivityType = activityType;
            this.ConnectionString = connString;
            this.ModifiedBy = modifiedBy;
            this.ModifiedName = modifiedName;
        }

        public RequestWFItemNew(int requestType, int requestTypeNo, ActivityType activityType, string connString, int modifiedBy, string modifiedName)
        {
            this.RequestTypeInt = requestType;
            this.RequestTypeNo = requestTypeNo;
            this.ActivityType = activityType;
            this.ConnectionString = connString;
            this.ModifiedBy = modifiedBy;
            this.ModifiedName = modifiedName;
        }

        public RequestWFItemNew(RequestType requestType, int requestTypeNo,
            ActivityType activityType, string connString,
            string fromEmail, string fromName, int modifiedBy, string modifiedName)
        {
            this.RequestType = requestType;
            this.RequestTypeNo = requestTypeNo;
            this.ActivityType = activityType;
            this.ConnectionString = connString;
            this.FromEmail = fromEmail;
            this.FromName = FromName;
            this.ModifiedBy = modifiedBy;
            this.ModifiedName = modifiedName;
        }

        public RequestWFItemNew(int requestType, int requestTypeNo,
            ActivityType activityType, string connString,
            string fromEmail, string fromName, int modifiedBy, string modifiedName)
        {
            this.RequestTypeInt = requestType;
            this.RequestTypeNo = requestTypeNo;
            this.ActivityType = activityType;
            this.ConnectionString = connString;
            this.FromEmail = fromEmail;
            this.FromName = FromName;
            this.ModifiedBy = modifiedBy;
            this.ModifiedName = modifiedName;
        }
        #endregion
    }
}
