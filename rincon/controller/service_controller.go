package controller

import (
	"github.com/gin-gonic/gin"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	oteltrace "go.opentelemetry.io/otel/trace"
	"net/http"
	"rincon/config"
	"rincon/model"
	"rincon/service"
	"strconv"
	"time"
)

func GetAllServices(c *gin.Context) {
	// Start tracing span
	tr := otel.Tracer(config.Service.Name)
	_, span := tr.Start(c.Request.Context(), "GetAllServices", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	result := service.GetAllServices()
	c.JSON(http.StatusOK, result)
}

func GetService(c *gin.Context) {
	// Start tracing span
	tr := otel.Tracer(config.Service.Name)
	_, span := tr.Start(c.Request.Context(), "GetService", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	if i, err := strconv.Atoi(c.Param("name")); err == nil {
		// integer id passed
		result := service.GetServiceByID(i)
		if result.ID != i {
			c.JSON(http.StatusNotFound, gin.H{"message": "No service with id " + strconv.Itoa(i) + " found"})
			return
		}
		c.JSON(http.StatusOK, result)
		return
	}
	// string name passed
	result := service.GetServiceByName(c.Param("name"))
	c.JSON(http.StatusOK, result)
}

func CreateService(c *gin.Context) {
	// Start tracing span
	tr := otel.Tracer(config.Service.Name)
	_, span := tr.Start(c.Request.Context(), "CreateService", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	var input model.Service
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := service.CreateService(input); err != nil {
		c.JSON(http.StatusInternalServerError, err)
		return
	}
	c.JSON(http.StatusOK, input)
}

func RegisterSelf() {
	// Remove any previously registered Rincon instances
	services := service.GetServiceByName("Rincon")
	for i, s := range services {
		println("Removing existing instance " + strconv.Itoa(i) + " of Rincon from Registry")
		_ = service.RemoveService(s)
	}
	// Register service with registry
	var s model.Service
	s.Name = "Rincon"
	s.Version = config.Version
	s.URL = "http://rincon:" + config.Port
	s.Port, _ = strconv.Atoi(config.Port)
	s.StatusEmail = config.StatusEmail
	s.CreatedAt = time.Now()
	service.CreateService(s)
	// Get service to set config.Service
	config.Service = service.GetServiceByName("Rincon")[0]
	// Register routes with service
	service.CreateRoute(model.Route{
		Route:       "/rincon",
		ServiceName: "Rincon",
		CreatedAt:   time.Now(),
	})
	service.CreateRoute(model.Route{
		Route:       "/status",
		ServiceName: "Rincon",
		CreatedAt:   time.Now(),
	})
	service.CreateRoute(model.Route{
		Route:       "/services",
		ServiceName: "Rincon",
		CreatedAt:   time.Now(),
	})
	service.CreateRoute(model.Route{
		Route:       "/routes",
		ServiceName: "Rincon",
		CreatedAt:   time.Now(),
	})
}
