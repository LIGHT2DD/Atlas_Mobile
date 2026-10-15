import datetime as dt
from functools import wraps
from typing import Callable
from fastapi import Request, Response
from fastapi.responses import RedirectResponse


def inject_context(request: Request):
    csrf_token = getattr(request.state, "csrf_token", None) or request.cookies.get("csrf_token", "")
    return {
        "request": request,
        "app_name": "ATLAS",
        "app_full_name": "Academic Thesis Lifecycle & Assessment Suite",
        "app_version": "2.0.0",
        "footer_message": "Academic Thesis Lifecycle & Assessment Suite",
        "year": dt.datetime.now().year,
        "csrf_token": csrf_token,
    }
  
  
def add_template_context(template_path: str):
    def decorator(func: Callable):
        @wraps(func)
        async def wrapper(*args, **kwargs) -> Response:
            # Find the Request object from kwargs or args
            request = kwargs.get('request')
            if not request:
                for arg in args:
                    if isinstance(arg, Request):
                        request = arg
                        break
            if not request:
                raise ValueError("Request object not found in route arguments")

            # Get the template engine from the request app state to avoid circular imports
            frontend = request.app.state.frontend
                        
            # Get additional context from the injected dependency
            context_data = inject_context(request)
                        
            # Run the route function to get extra context data from the function itself
            result = await func(*args, **kwargs)
            
            # Check if the function returned a RedirectResponse (usually for POST redirection)
            if isinstance(result, RedirectResponse):
                return result
            
            # Merge function data with context_data
            context = {
                'page': template_path.split('/')[-1].replace('.html', ''),
                **context_data, 
                **(result if isinstance(result, dict) else {})
            }
            
            return frontend.TemplateResponse(template_path, context)
        return wrapper
    return decorator  
