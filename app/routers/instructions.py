from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy.orm import Session

from app.auth import get_current_user
from app.database import get_db
from app.models import Instruction
from app.schemas import InstructionCreate, InstructionRead

router = APIRouter(prefix="/instructions", tags=["instructions"])


@router.get("", response_model=list[InstructionRead])
def list_instructions(
    _: str = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[Instruction]:
    return db.query(Instruction).order_by(Instruction.created_at.desc()).all()


@router.post("", response_model=InstructionRead, status_code=status.HTTP_201_CREATED)
def create_instruction(
    payload: InstructionCreate,
    _: str = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Instruction:
    instruction = Instruction(title=payload.title, content=payload.content)
    db.add(instruction)
    db.commit()
    db.refresh(instruction)
    return instruction


@router.delete("/{instruction_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_instruction(
    instruction_id: UUID,
    _: str = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Response:
    instruction = db.get(Instruction, instruction_id)
    if instruction is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Instruction not found")

    db.delete(instruction)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
