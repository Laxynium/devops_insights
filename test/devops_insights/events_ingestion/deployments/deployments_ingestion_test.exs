defmodule DevopsInsights.EventsIngestion.Deployments.DeploymentIngestionTest do
  alias DevopsInsights.EventsIngestion.Deployments.Deployment
  use DevopsInsights.DataCase

  alias DevopsInsights.EventsIngestion.Deployments.DeploymentsGateway

  describe "deployments" do
    alias DevopsInsights.EventsIngestion.Deployments.Deployment

    import DevopsInsights.EventsIngestionFixtures

    @invalid_attrs %{timestamp: nil, type: nil, serviceName: nil, environment: nil}

    test "list all deployments" do
      deployment = deployment_fixture()
      assert DeploymentsGateway.list_deployments() == [deployment]
    end

    test "create a deployment" do
      valid_attrs = %{
        timestamp: ~U[2024-03-06 22:39:00Z],
        serviceName: "some serviceName",
        environment: "some environment"
      }

      assert {:ok, %Deployment{} = deployment} = DeploymentsGateway.create_deployment(valid_attrs)
      assert deployment.timestamp == ~U[2024-03-06 22:39:00Z]
      assert deployment.serviceName == "some serviceName"
      assert deployment.environment == "some environment"
    end

    test "create a deployment fails when some properties are invalid" do
      assert {:error, %Ecto.Changeset{}} = DeploymentsGateway.create_deployment(@invalid_attrs)
    end
  end
end
