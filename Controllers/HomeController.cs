using Microsoft.AspNetCore.Mvc;
using ExampleApp.Models;
using Microsoft.Extensions.Configuration;
namespace ExampleApp.Controllers
{
    public class HomeController : Controller
    {
        private IRepository repository;
        private string message;
        public HomeController(IRepository repo, IConfiguration config)
        {
            repository = repo;
            message = config["HOSTNAME"] ?? "Essential Docker";
        }
        public IActionResult Index()
        {
            ViewBag.Message = message;
            throw new System.Exception("I like an error!");
            return View(repository.Products);
        }
    }
}