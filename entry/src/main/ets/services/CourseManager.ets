import { RDBService } from './RDBService';
import { Course, CourseCreateInput, CourseStatus } from '../model/Course';
import { generateUUID } from '../utils/UUIDUtil';

export class CourseManager {
  private rdbService: RDBService;

  constructor(rdbService: RDBService) {
    this.rdbService = rdbService;
  }

  async createCourse(input: CourseCreateInput): Promise<Course> {
    const now = Date.now();
    const course: Course = {
      id: generateUUID(),
      name: input.name,
      question: input.question,
      status: 'created',
      mentalModelGenerated: false,
      controversyGenerated: false,
      assessmentGenerating: false,
      createdAt: now,
      updatedAt: now
    };

    await this.rdbService.insertCourse(course);
    console.info(`[CourseManager] Course created: ${course.id}`);
    
    return course;
  }

  async getAllCourses(): Promise<Course[]> {
    return await this.rdbService.queryCourses();
  }

  async getCourseById(courseId: string): Promise<Course | null> {
    const courses = await this.getAllCourses();
    return courses.find(c => c.id === courseId) || null;
  }

  async updateCourseStatus(courseId: string, status: CourseStatus): Promise<void> {
    const course = await this.getCourseById(courseId);
    if (!course) {
      throw new Error('课程不存在');
    }

    course.status = status;
    course.updatedAt = Date.now();
    await this.rdbService.updateCourse(course);
  }

  async markMentalModelGenerated(courseId: string): Promise<void> {
    const course = await this.getCourseById(courseId);
    if (!course) {
      throw new Error('课程不存在');
    }

    course.mentalModelGenerated = true;
    course.updatedAt = Date.now();
    
    // If both Q1 and Q2 are generated, set status to active
    if (course.controversyGenerated) {
      course.status = 'active';
    }
    
    await this.rdbService.updateCourse(course);
  }

  async markControversyGenerated(courseId: string): Promise<void> {
    const course = await this.getCourseById(courseId);
    if (!course) {
      throw new Error('课程不存在');
    }

    course.controversyGenerated = true;
    course.updatedAt = Date.now();
    
    // If both Q1 and Q2 are generated, set status to active
    if (course.mentalModelGenerated) {
      course.status = 'active';
    }
    
    await this.rdbService.updateCourse(course);
  }

  async archiveCourse(courseId: string): Promise<void> {
    await this.updateCourseStatus(courseId, 'archived');
  }

  async completeCourse(courseId: string): Promise<void> {
    await this.updateCourseStatus(courseId, 'completed');
  }

  async deleteCourse(courseId: string): Promise<void> {
    // RDB cascade will delete related knowledge nodes, edges, and assessments
    await this.rdbService.deleteCourse(courseId);
    console.info(`[CourseManager] Course deleted: ${courseId}`);
  }

  async searchCourses(query: string): Promise<Course[]> {
    const allCourses = await this.getAllCourses();
    const lowerQuery = query.toLowerCase();
    
    return allCourses.filter(course => 
      course.name.toLowerCase().includes(lowerQuery) ||
      course.question.toLowerCase().includes(lowerQuery)
    );
  }

  async getActiveCourses(): Promise<Course[]> {
    const allCourses = await this.getAllCourses();
    return allCourses.filter(c => c.status === 'active');
  }

  async getCourseProgress(courseId: string): Promise<number> {
    const course = await this.getCourseById(courseId);
    if (!course) return 0;

    let progress = 0;
    if (course.mentalModelGenerated) progress += 50;
    if (course.controversyGenerated) progress += 50;
    
    return progress;
  }
}
