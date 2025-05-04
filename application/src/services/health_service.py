import logging
from datetime import datetime, timezone
import psutil

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class HealthService:
    @staticmethod
    def check_health():
        """
        Perform system health check and return status information.
        Includes basic system metrics like CPU and memory usage.
        """
        logger.info("Performing health check")
        
        try:
            # Get basic system metrics
            cpu_percent = psutil.cpu_percent()
            memory = psutil.virtual_memory()
            disk = psutil.disk_usage('/')
            
            health_info = {
                "status": "healthy",
                "timestamp": datetime.now(timezone.utc),
                "system_info": {
                    "cpu_usage_percent": cpu_percent,
                    "memory_usage_percent": memory.percent,
                    "disk_usage_percent": disk.percent
                }
            }
            
            logger.info("Health check completed successfully")
            return health_info
            
        except Exception as e:
            logger.error(f"Health check failed: {str(e)}")
            return {
                "status": "unhealthy",
                "timestamp": datetime.now(datetime.timezone.utc),
                "error": str(e)
            }