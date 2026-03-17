// LM Studio implementation of InferenceClient interface
// Uses the OpenAI-compatible REST API served by LM Studio
// Default endpoint: http://localhost:1234/v1

import type { Logger } from '@semiont/core';
import { InferenceClient, InferenceResponse } from '../interface.js';

interface OpenAIMessage {
  role: 'system' | 'user' | 'assistant';
  content: string;
}

interface OpenAIChatResponse {
  id: string;
  object: string;
  choices: Array<{
    index: number;
    message: OpenAIMessage;
    finish_reason: string | null;
  }>;
  usage?: {
    prompt_tokens: number;
    completion_tokens: number;
    total_tokens: number;
  };
}

export class LMStudioInferenceClient implements InferenceClient {
  private baseURL: string;
  private model: string;
  private logger?: Logger;

  constructor(model: string, baseURL?: string, logger?: Logger) {
    this.baseURL = (baseURL || 'http://localhost:1234/v1').replace(/\/+$/, '');
    this.model = model;
    this.logger = logger;
  }

  async generateText(prompt: string, maxTokens: number, temperature: number): Promise<string> {
    const response = await this.generateTextWithMetadata(prompt, maxTokens, temperature);
    return response.text;
  }

  async generateTextWithMetadata(prompt: string, maxTokens: number, temperature: number): Promise<InferenceResponse> {
    this.logger?.debug('Generating text with LM Studio', {
      model: this.model,
      promptLength: prompt.length,
      maxTokens,
      temperature,
    });

    const url = `${this.baseURL}/chat/completions`;

    const res = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: this.model,
        messages: [{ role: 'user', content: prompt }],
        max_tokens: maxTokens,
        temperature,
        stream: false,
      }),
    });

    if (!res.ok) {
      const body = await res.text();
      this.logger?.error('LM Studio API error', {
        model: this.model,
        status: res.status,
        body,
      });
      throw new Error(`LM Studio API error (${res.status}): ${body}`);
    }

    const data = await (async () => {
      const text = await res.text();
      try {
        return JSON.parse(text) as OpenAIChatResponse;
      } catch {
        throw new Error(`LM Studio returned invalid JSON. Raw response: ${text.slice(0, 200)}`);
      }
    })();

    const choice = data.choices?.[0];

    if (!choice?.message?.content) {
      this.logger?.error('Empty response from LM Studio', { model: this.model });
      throw new Error('Empty response from LM Studio');
    }

    const stopReason = mapFinishReason(choice.finish_reason);

    this.logger?.info('Text generation completed', {
      model: this.model,
      textLength: choice.message.content.length,
      stopReason,
    });

    return {
      text: choice.message.content,
      stopReason,
    };
  }
}

function mapFinishReason(reason: string | null | undefined): string {
  switch (reason) {
    case 'stop': return 'end_turn';
    case 'length': return 'max_tokens';
    default: return reason || 'unknown';
  }
}
