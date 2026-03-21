from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.routers import scoring, spaced_repetition, recommendation

app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    docs_url="/docs",
    redoc_url="/redoc",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(scoring.router, prefix="/scoring", tags=["scoring"])
app.include_router(spaced_repetition.router, prefix="/spaced-repetition", tags=["spaced-repetition"])
app.include_router(recommendation.router, prefix="/recommendation", tags=["recommendation"])


@app.get("/health")
def health():
    return {"status": "ok", "version": settings.app_version}
