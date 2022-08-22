using Pulumi;
using Pulumi.AzureNative.Resources;
using Pulumi.AzureNative.Storage;
using Pulumi.AzureNative.Storage.Inputs;
using System.Collections.Generic;

return await Pulumi.Deployment.RunAsync(() =>
{
    var config = new Pulumi.Config();
    var projectName = config.Require("projectName");
    
    var rg = new ResourceGroup("rg", new ResourceGroupArgs {
      ResourceGroupName = projectName
    });
    
    var workspaceName = $"{projectName}-ws";
    var appInsightsName = $"{projectName}-ai";
    var storageAccountName = $"{projectName.Replace("-","").ToLower()}";
    var appSvcPlanName = $"{projectName}-sv-plan";
    var webAppName = $"{projectName}-web";
    
    var laws = new Pulumi.AzureNative.OperationalInsights.Workspace(workspaceName, new Pulumi.AzureNative.OperationalInsights.WorkspaceArgs{
      ResourceGroupName = rg.Name,
      Sku = new Pulumi.AzureNative.OperationalInsights.Inputs.WorkspaceSkuArgs {
        Name = "PerGB2018"
      }
    }, new CustomResourceOptions { Parent = rg });
    
    var ai = new Pulumi.AzureNative.Insights.V20200202.Component(appInsightsName, new Pulumi.AzureNative.Insights.V20200202.ComponentArgs {
      ResourceGroupName = rg.Name,
      Kind = "web",
      ApplicationType = "web",
      WorkspaceResourceId = laws.Id
    }, new CustomResourceOptions { Parent = laws });
    
    var storage = new Pulumi.AzureNative.Storage.StorageAccount(storageAccountName, new Pulumi.AzureNative.Storage.StorageAccountArgs {
      ResourceGroupName = rg.Name,
      Sku = new Pulumi.AzureNative.Storage.Inputs.SkuArgs {
        Name = "Standard_LRS"
      },
      Kind = Pulumi.AzureNative.Storage.Kind.StorageV2
    }, new CustomResourceOptions { Parent = rg });
    
    var appSvcPlan = new Pulumi.AzureNative.Web.AppServicePlan(appSvcPlanName, new Pulumi.AzureNative.Web.AppServicePlanArgs {
      ResourceGroupName = rg.Name,
      Sku = new Pulumi.AzureNative.Web.Inputs.SkuDescriptionArgs {
        Name = "B1",
        Capacity = 1
      }
    }, new CustomResourceOptions { Parent = rg });
    
    var app = new Pulumi.AzureNative.Web.WebApp(webAppName, new Pulumi.AzureNative.Web.WebAppArgs{
      ResourceGroupName = rg.Name,
      ServerFarmId = appSvcPlan.Id,
      HttpsOnly = true,
      SiteConfig = new Pulumi.AzureNative.Web.Inputs.SiteConfigArgs {
        MinTlsVersion = "1.2",
        AppSettings = new[] {
            new Pulumi.AzureNative.Web.Inputs.NameValuePairArgs {
                Name = "APPINSIGHTS_INSTRUMENTATIONKEY",
                Value = ai.InstrumentationKey
            }
        },
        ConnectionStrings = new[] {
          new Pulumi.AzureNative.Web.Inputs.ConnStringInfoArgs {
            Type = Pulumi.AzureNative.Web.ConnectionStringType.Custom,
            Name = "Storage",
            ConnectionString = GetStorageConnectionString(rg, storage)
          }
        }
      }
    }, new CustomResourceOptions { Parent = appSvcPlan });
    
    return new Dictionary<string, object?> {
      { "websiteUrl", app.DefaultHostName.Apply(x => $"https://{x}/") }
    };
});

static Output<string> GetStorageConnectionString(ResourceGroup resourceGroup, Pulumi.AzureNative.Storage.StorageAccount account)
{
  var primaryStorageKey = Output.Tuple(resourceGroup.Name, account.Name).Apply(
    x => Output.Create(Pulumi.AzureNative.Storage.ListStorageAccountKeys.InvokeAsync(
                       new Pulumi.AzureNative.Storage.ListStorageAccountKeysArgs {
                         ResourceGroupName = x.Item1,
                         AccountName = x.Item2
                       }).ContinueWith(x => x.Result.Keys[0].Value)
    )
  );

  return Output.Tuple(account.Name, primaryStorageKey).Apply(x => $"DefaultEndpointsProtocol=https;AccountName={x.Item1};AccountKey={x.Item2}");
}