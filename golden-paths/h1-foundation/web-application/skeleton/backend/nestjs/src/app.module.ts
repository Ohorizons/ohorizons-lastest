import { Module, Controller, Get } from '@nestjs/common';

@Controller()
class AppController {
  @Get('health')
  health() {
    return { status: 'healthy' };
  }

  @Get('api/items')
  listItems() {
    return { items: [] };
  }
}

@Module({
  controllers: [AppController],
})
export class AppModule {}
