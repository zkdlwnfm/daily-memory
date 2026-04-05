import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { SearchService } from './search.service';
import { SemanticSearchDto } from './dto/semantic-search.dto';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import { CurrentUser, AuthUser } from '../auth/decorators/current-user.decorator';

@ApiTags('Search')
@ApiBearerAuth()
@UseGuards(FirebaseAuthGuard)
@Controller('search')
export class SearchController {
  constructor(private readonly searchService: SearchService) {}

  @Post('semantic')
  async semanticSearch(@Body() dto: SemanticSearchDto, @CurrentUser() user: AuthUser) {
    const results = await this.searchService.semanticSearch(
      user.uid,
      dto.query,
      dto.limit,
      dto.threshold,
    );
    return { results, count: results.length };
  }
}
