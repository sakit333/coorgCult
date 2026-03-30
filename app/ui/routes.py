from fastapi import APIRouter, Request, Path
from fastapi.responses import HTMLResponse, RedirectResponse
from app.core.config import templates

router = APIRouter(tags=["UI Routing"])

@router.get("/")
async def root_redirect():
    # Redirect base url to login by default
    return RedirectResponse(url="/login")

@router.get("/login", response_class=HTMLResponse)
async def login_page(request: Request):
    return templates.TemplateResponse(name="login.html", context={"request": request}, request=request)

@router.get("/signup", response_class=HTMLResponse)
async def signup_page(request: Request):
    return templates.TemplateResponse(name="signup.html", context={"request": request}, request=request)

@router.get("/home/{session_id}", response_class=HTMLResponse)
async def home_page(request: Request, session_id: str = Path(..., title="The session UUID")):
    return templates.TemplateResponse(name="index.html", context={"request": request, "session_id": session_id}, request=request)
