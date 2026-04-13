import { Controller, Get, Post, Put, Delete, Patch, Body, Param, Query, Req, UseGuards, NotFoundException } from '@nestjs/common';
import { TaskService } from './task.service';
import { CreateTaskDto, UpdateTaskDto, TaskQueryDto } from './dto/create-task.dto';
import { AuthGuard } from '../auth/auth.guard';

@Controller('tasks')
@UseGuards(AuthGuard)
export class TaskController {
  constructor(private readonly taskService: TaskService) {}

  @Post()
  async create(@Req() req: any, @Body() dto: CreateTaskDto) {
    return this.taskService.create(req.user.uid, dto);
  }

  @Get()
  async findAll(@Req() req: any, @Query() query: TaskQueryDto) {
    return this.taskService.findAll(req.user.uid, query);
  }

  @Get(':id')
  async findOne(@Req() req: any, @Param('id') id: string) {
    const task = await this.taskService.findOne(req.user.uid, id);
    if (!task) throw new NotFoundException('Task not found');
    return task;
  }

  @Put(':id')
  async update(@Req() req: any, @Param('id') id: string, @Body() dto: UpdateTaskDto) {
    const task = await this.taskService.update(req.user.uid, id, dto);
    if (!task) throw new NotFoundException('Task not found');
    return task;
  }

  @Patch(':id/status')
  async updateStatus(@Req() req: any, @Param('id') id: string, @Body('status') status: string) {
    const task = await this.taskService.updateStatus(req.user.uid, id, status);
    if (!task) throw new NotFoundException('Task not found');
    return task;
  }

  @Delete(':id')
  async remove(@Req() req: any, @Param('id') id: string) {
    const deleted = await this.taskService.remove(req.user.uid, id);
    if (!deleted) throw new NotFoundException('Task not found');
    return { deleted: true };
  }
}
