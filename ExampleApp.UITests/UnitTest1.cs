namespace ExampleApp.UITests;

public class UnitTest1
{
    [Fact]
    public void Test1()
    {
        IWebDriver driver = new FirefoxDriver();
        driver.Navigate().GoToUrl("http://www.google.com");
        IWebElement element = driver.FindElement(By.Name("q"));
        element.SendKeys("Hello Selenium WebDriver");
        element.Submit();
    }
}