namespace CEAApp.Web.Models
{
    public class FileUpload
    {
        public string FileName { get; set; }
        public string ContentType { get; set; }

        public IFormFile FormFile { get; set; }

    }
}
