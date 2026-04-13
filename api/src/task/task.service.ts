import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { TaskEntity } from './entities/task.entity';
import { CreateTaskDto, UpdateTaskDto, TaskQueryDto } from './dto/create-task.dto';

@Injectable()
export class TaskService {
  constructor(
    @InjectRepository(TaskEntity)
    private taskRepo: Repository<TaskEntity>,
  ) {}

  async create(userId: string, dto: CreateTaskDto): Promise<TaskEntity> {
    const task = this.taskRepo.create({
      userId,
      title: dto.title,
      description: dto.description,
      memoryId: dto.memoryId,
      personId: dto.personId,
      dueDate: dto.dueDate ? new Date(dto.dueDate) : undefined,
      quadrant: dto.quadrant ?? 'Q2',
      isAiSuggested: dto.isAiSuggested ?? true,
      aiConfidence: dto.aiConfidence,
    });
    return this.taskRepo.save(task);
  }

  async findAll(userId: string, query: TaskQueryDto): Promise<TaskEntity[]> {
    const qb = this.taskRepo.createQueryBuilder('task')
      .where('task.user_id = :userId', { userId })
      .orderBy('task.due_date', 'ASC', 'NULLS LAST')
      .addOrderBy('task.created_at', 'DESC');

    if (query.status) {
      qb.andWhere('task.status = :status', { status: query.status });
    }
    if (query.quadrant) {
      qb.andWhere('task.quadrant = :quadrant', { quadrant: query.quadrant });
    }
    if (query.personId) {
      qb.andWhere('task.person_id = :personId', { personId: query.personId });
    }
    if (query.from) {
      qb.andWhere('task.due_date >= :from', { from: new Date(query.from) });
    }
    if (query.to) {
      qb.andWhere('task.due_date <= :to', { to: new Date(query.to) });
    }

    return qb.getMany();
  }

  async findOne(userId: string, id: string): Promise<TaskEntity | null> {
    return this.taskRepo.findOne({ where: { id, userId } });
  }

  async update(userId: string, id: string, dto: UpdateTaskDto): Promise<TaskEntity | null> {
    const task = await this.taskRepo.findOne({ where: { id, userId } });
    if (!task) return null;

    if (dto.title !== undefined) task.title = dto.title;
    if (dto.description !== undefined) task.description = dto.description;
    if (dto.personId !== undefined) task.personId = dto.personId;
    if (dto.dueDate !== undefined) task.dueDate = new Date(dto.dueDate);
    if (dto.quadrant !== undefined) task.quadrant = dto.quadrant;
    if (dto.status !== undefined) task.status = dto.status;

    return this.taskRepo.save(task);
  }

  async updateStatus(userId: string, id: string, status: string): Promise<TaskEntity | null> {
    const task = await this.taskRepo.findOne({ where: { id, userId } });
    if (!task) return null;

    task.status = status;
    return this.taskRepo.save(task);
  }

  async remove(userId: string, id: string): Promise<boolean> {
    const result = await this.taskRepo.delete({ id, userId });
    return (result.affected ?? 0) > 0;
  }
}
