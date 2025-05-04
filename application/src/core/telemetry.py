from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.resources import Resource
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.logging import LoggingInstrumentor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.sdk.resources import SERVICE_NAME
from .config import get_settings
import logging
from contextlib import contextmanager

def setup_telemetry():
    """Setup OpenTelemetry with OTLP exporter."""
    settings = get_settings()
    
    # Configure the tracer provider
    resource = Resource.create({SERVICE_NAME: settings.otel_service_name})
    tracer_provider = TracerProvider(resource=resource)
    
    # Configure the OTLP exporter
    otlp_exporter = OTLPSpanExporter(
        endpoint=settings.otel_collector_endpoint,
        insecure=settings.otel_insecure
    )
    
    # Add BatchSpanProcessor to the tracer provider
    span_processor = BatchSpanProcessor(otlp_exporter)
    tracer_provider.add_span_processor(span_processor)
    
    # Set the tracer provider
    trace.set_tracer_provider(tracer_provider)
    
    # Instrument logging
    LoggingInstrumentor().instrument(set_logging_format=True)
    
    # Create a logger for this module
    logger = logging.getLogger(__name__)
    logger.info(f"Telemetry initialized for service: {settings.otel_service_name}")
    
    return tracer_provider

@contextmanager
def create_span(name: str, context: dict = None):
    """Create a new span with the given name and optional context."""
    tracer = trace.get_tracer(__name__)
    with tracer.start_as_current_span(name) as span:
        if context:
            for key, value in context.items():
                span.set_attribute(key, value)
        yield span