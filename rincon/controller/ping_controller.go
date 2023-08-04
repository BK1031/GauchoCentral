package controller

import (
	"github.com/gin-gonic/gin"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	oteltrace "go.opentelemetry.io/otel/trace"
	"net/http"
	"rincon/config"
)

func Ping(c *gin.Context) {
	// Start tracing span
	tr := otel.Tracer(config.Service.Name)
	_, span := tr.Start(c.Request.Context(), "Ping", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	c.JSON(http.StatusOK, gin.H{"message": "Rincon v" + config.Version + " is online!"})
}
